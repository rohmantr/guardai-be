package agent

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"
)

type LLMClient struct {
	apiKey    string
	model     string
	client    *http.Client
	CustomURL string // added for testing
}

func NewLLMClient(apiKey, model string) *LLMClient {
	return &LLMClient{
		apiKey: apiKey,
		model:  model,
		client: &http.Client{},
	}
}

type chatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type responseFormat struct {
	Type string `json:"type"`
}

type openAIRequest struct {
	Model          string         `json:"model"`
	Messages       []chatMessage  `json:"messages"`
	Temperature    float64        `json:"temperature"`
	MaxTokens      int            `json:"max_tokens"`
	ResponseFormat responseFormat `json:"response_format"`
}

type openAIResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error"`
}

func (c *LLMClient) Generate(ctx context.Context, systemPrompt, userPrompt string) (string, error) {
	if c.apiKey == "" {
		return "", errors.New("missing LLM_API_KEY")
	}

	reqBody := openAIRequest{
		Model: c.model,
		Messages: []chatMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature:    0.0,
		MaxTokens:      200,
		ResponseFormat: responseFormat{Type: "json_object"},
	}

	bodyBytes, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}

	var lastErr error
	backoffs := []time.Duration{1 * time.Second, 2 * time.Second}
	url := "https://api.openai.com/v1/chat/completions"
	if c.CustomURL != "" {
		url = c.CustomURL
	}

	for attempt := 0; attempt <= len(backoffs); attempt++ {
		if attempt > 0 {
			select {
			case <-ctx.Done():
				return "", ctx.Err()
			case <-time.After(backoffs[attempt-1]):
			}
		}

		reqCtx, cancel := context.WithTimeout(ctx, 4*time.Second)
		req, err := http.NewRequestWithContext(reqCtx, "POST", url, bytes.NewReader(bodyBytes))
		if err != nil {
			cancel()
			return "", err
		}
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+c.apiKey)

		resp, err := c.client.Do(req)
		if err != nil {
			cancel()
			lastErr = err
			continue
		}

		if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden || resp.StatusCode == http.StatusBadRequest {
			defer resp.Body.Close()
			var oaiResp openAIResponse
			_ = json.NewDecoder(resp.Body).Decode(&oaiResp)
			cancel()
			msg := fmt.Sprintf("llm request failed with status: %d", resp.StatusCode)
			if oaiResp.Error != nil {
				msg = fmt.Sprintf("%s: %s", msg, oaiResp.Error.Message)
			}
			return "", errors.New(msg)
		}

		if resp.StatusCode != http.StatusOK {
			resp.Body.Close()
			cancel()
			lastErr = fmt.Errorf("llm request failed with status: %d", resp.StatusCode)
			continue
		}

		var oaiResp openAIResponse
		err = json.NewDecoder(resp.Body).Decode(&oaiResp)
		resp.Body.Close()
		cancel()

		if err != nil {
			lastErr = err
			continue
		}

		if len(oaiResp.Choices) == 0 {
			lastErr = errors.New("empty choices from llm response")
			continue
		}

		return oaiResp.Choices[0].Message.Content, nil
	}

	return "", lastErr
}
