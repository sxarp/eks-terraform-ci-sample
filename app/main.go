package main

import (
	"context"
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gorilla/mux"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s!", r.URL.Path[1:])
}

// 負荷試験用
func slowHandler(w http.ResponseWriter, r *http.Request) {
	v := 0.5
	for i := 0; i < 9999999; i++ {
		v = math.Cos(v)
	}
	fmt.Fprintf(w, "OK: v=%f", v)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Println(r.RequestURI)
		next.ServeHTTP(w, r)
	})
}

func startServer(srv *http.Server) {
	go func() {
		log.Fatal(srv.ListenAndServe())
	}()

	log.Printf("Started server listening at %s.\n", srv.Addr)
}

// Ref https://github.com/gorilla/mux#graceful-shutdown
func gracefulShutdown(srv *http.Server) {
	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
	<-c
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*15)
	defer cancel()
	srv.Shutdown(ctx)
	log.Println("shutting down")
	os.Exit(0)
}

func main() {
	r := mux.NewRouter()
	r.HandleFunc("/slow", slowHandler).Methods("GET")
	r.HandleFunc("/{.*}", handler).Methods("GET")
	r.Use(loggingMiddleware)

	srv := &http.Server{
		Handler: r,
		Addr:    "0.0.0.0:8080",

		WriteTimeout: 15 * time.Second,
		ReadTimeout:  15 * time.Second,
	}

	startServer(srv)
	gracefulShutdown(srv)
}
