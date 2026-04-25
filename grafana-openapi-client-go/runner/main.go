package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/grafana/grafana-openapi-client-go/client"
	"github.com/grafana/grafana-openapi-client-go/client/access_control"
	"github.com/grafana/grafana-openapi-client-go/models"
)

func main() {
	host := os.Getenv("MOCK_HOST")
	if host == "" {
		host = "wiremock:8080"
	}

	resetScenarios(host)

	roleBody := &models.CreateRoleForm{
		Name:        "custom:test:write-dashboards",
		DisplayName: "Custom Write Dashboards Role",
		Description: "Allows writing dashboards",
	}

	// Run 1: default config — 403 is not in the default retry list [429, 5xx]
	fmt.Println("=== Run 1: default config (RetryStatusCodes defaults to [429, 5xx]) ===")
	fmt.Println("POST /api/access-control/roles — WireMock will return 403")
	c1 := client.NewHTTPClientWithConfig(nil, &client.TransportConfig{
		Host:     host,
		BasePath: "/api",
		Schemes:  []string{"http"},
	})
	_, err := c1.AccessControl.CreateRole(roleBody)
	if err != nil {
		if forbidden, ok := err.(*access_control.CreateRoleForbidden); ok {
			fmt.Printf("→ Got *CreateRoleForbidden (HTTP 403): %q\n", *forbidden.Payload.Message)
		} else {
			fmt.Printf("→ Got %T: %v\n", err, err)
		}
	} else {
		fmt.Println("→ Unexpected success!")
	}

	resetScenarios(host)

	// Run 2: 403 added to the retry list, 3 retries = 4 total attempts
	// WireMock returns 403 on attempts 1-3, then 201 on attempt 4
	fmt.Println("\n=== Run 2: NumRetries=3, RetryStatusCodes=[\"403\"] ===")
	fmt.Println("POST /api/access-control/roles — WireMock returns 403 x3, then 201")
	c2 := client.NewHTTPClientWithConfig(nil, &client.TransportConfig{
		Host:             host,
		BasePath:         "/api",
		Schemes:          []string{"http"},
		NumRetries:       3,
		RetryStatusCodes: []string{"403"},
		//RetryTimeout:     200 * time.Millisecond,
	})
	result, err := c2.AccessControl.CreateRole(roleBody)
	if err != nil {
		fmt.Printf("→ Got %T: %v\n", err, err)
	} else {
		fmt.Printf("→ Success after retries! Role %q created (uid: %q)\n", *result.Payload.Name, *result.Payload.UID)
	}

	resetScenarios(host)

	// Run 3: demonstrates the context-deadline bug (https://github.com/grafana/grafana-openapi-client-go/pull/137)
	//
	// The client gets 403, decides to retry, and sleeps backoff(1)=2s before the next attempt.
	// The context deadline (300ms) expires during that sleep.
	//
	// Buggy behaviour (time.Sleep): ignores the deadline, returns after the full 2s backoff.
	// Fixed behaviour (select on ctx.Done): returns context.DeadlineExceeded at ~300ms.
	fmt.Println("\n=== Run 3: context deadline expires during retry backoff sleep ===")
	fmt.Println("POST /api/access-control/roles — context deadline=300ms, backoff(1)=2s")
	c3 := client.NewHTTPClientWithConfig(nil, &client.TransportConfig{
		Host:             host,
		BasePath:         "/api",
		Schemes:          []string{"http"},
		NumRetries:       3,
		RetryStatusCodes: []string{"403"},
	})
	ctx, cancel := context.WithTimeout(context.Background(), 300*time.Millisecond)
	defer cancel()
	params := access_control.NewCreateRoleParamsWithContext(ctx).WithBody(roleBody)
	start := time.Now()
	_, err = c3.AccessControl.CreateRoleWithParams(params)
	elapsed := time.Since(start).Round(time.Millisecond)
	if err != nil {
		fmt.Printf("→ Got %T: %v\n", err, err)
		fmt.Printf("→ Returned after %v (deadline was 300ms, backoff was 2s)\n", elapsed)
		fmt.Printf("→ %s\n", classifyTiming(elapsed))
	} else {
		fmt.Println("→ Unexpected success!")
	}
}

// classifyTiming helps make the pass/fail behaviour obvious in the output.
func classifyTiming(elapsed time.Duration) string {
	if elapsed < 600*time.Millisecond {
		return "GOOD: returned promptly — context cancellation respected"
	}
	return "BAD: returned late — retry sleep blocked past the context deadline"
}

func resetScenarios(host string) {
	fmt.Printf("\n[resetting WireMock scenario to initial state]\n\n")
	resp, err := http.Post(fmt.Sprintf("http://%s/__admin/scenarios/reset", host), "", nil)
	if err != nil {
		log.Fatalf("failed to reset WireMock scenarios: %v", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		log.Fatalf("unexpected status resetting scenarios: %d", resp.StatusCode)
	}
}
