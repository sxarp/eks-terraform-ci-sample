package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
)

func panicif(err error) {
	if err != nil {
		panic(err)
	}
}

func TestHandler(t *testing.T) {
	path := "Sophie"
	req, err := http.NewRequest("GET", "/"+path, nil)
	panicif(err)

	rr, server := httptest.NewRecorder(), http.HandlerFunc(handler)
	server.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	if gotBody, wantBody := rr.Body.String(), fmt.Sprintf("Hello, %s!", path); gotBody != wantBody {
		t.Errorf("hendler returned wrong body: got [%v], want [%v]", gotBody, wantBody)
	}
}

func TestSlowHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/slow", nil)
	panicif(err)
	rr, server := httptest.NewRecorder(), http.HandlerFunc(slowHandler)
	server.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("status code is expected to be 200")
	}

	if r := rr.Body.String(); r != "OK: v=0.739085" {
		t.Errorf("Unexpected response body")
	}
}
