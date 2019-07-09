package main

import (
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Println(r.RequestURI)
		next.ServeHTTP(w, r)
	})
}

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/{.*}", handler).Methods("GET")
	r.Use(loggingMiddleware)

	srv := &http.Server{
		Handler: r,
		Addr:    "0.0.0.0:8080",

		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	log.Println("Start server...")

	log.Fatal(srv.ListenAndServe())
}
