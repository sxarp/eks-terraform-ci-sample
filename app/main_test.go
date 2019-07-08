package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func panicif(err error) {
	if err != nil {
		panic(err)
	}
}

func TestHandler(t *testing.T) {
	body := "Sophie"
	req, err := http.NewRequest("GET", "/", strings.NewReader(body))
	panicif(err)

	rr, server := httptest.NewRecorder(), http.HandlerFunc(handler)
	server.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	if gotBody, wantBody := rr.Body.String(), fmt.Sprintf("Hello, %s!", body); gotBody != wantBody {
		t.Errorf("hendler returned wrong body: got [%v], want [%v]", gotBody, wantBody)
	}
}
