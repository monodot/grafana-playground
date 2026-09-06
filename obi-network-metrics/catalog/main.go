package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

const defaultImageSize = 7 * 1024 * 1024

type catalogItem struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Image string `json:"image"`
}

func main() {
	imageSize := defaultImageSize
	if value := strings.TrimSpace(os.Getenv("CATALOG_IMAGE_SIZE_BYTES")); value != "" {
		var err error
		imageSize, err = strconv.Atoi(value)
		if err != nil {
			log.Fatalf("CATALOG_IMAGE_SIZE_BYTES must be an integer: %v", err)
		}
	}
	if imageSize < 1 {
		log.Fatalf("CATALOG_IMAGE_SIZE_BYTES must be positive")
	}

	// Create and fill a byte slice with predictable test data.
	// This lets us pretend we're serving a large image, without actually adding one to this repo.
	image := make([]byte, imageSize)
	for i := range image {
		image[i] = byte((i*31 + 17) % 251)
	}
	sum := sha256.Sum256(image)
	etag := `"` + hex.EncodeToString(sum[:]) + `"`

	// Define routes on this API
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok\n"))
	})
	mux.HandleFunc("/api/products", productsHandler)
	mux.HandleFunc("/images/products/", imageHandler(image, etag))

	// Define and start the web server
	port := strings.TrimSpace(os.Getenv("PORT"))
	if port == "" {
		port = "8080"
	}
	addr := ":" + port
	log.Printf("catalog listening on %s; image size=%d bytes", addr, imageSize)
	log.Fatal(http.ListenAndServe(addr, loggingMiddleware(mux)))
}

// Returns all products available and their image paths
func productsHandler(w http.ResponseWriter, r *http.Request) {
	items := []catalogItem{
		{ID: "egg-sandwich", Name: "Egg Sandwich", Image: "/images/products/egg-sandwich.jpg"},
		{ID: "egg-and-cheese-sandwich", Name: "Egg and Cheese Sandwich", Image: "/images/products/egg-and-cheese.jpg"},
		{ID: "fiesta-huevo-sandwich", Name: "Fiesta Huevo Sandwich", Image: "/images/products/fiesta-huevo.jpg"},
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(items)
}

// Returns an image (with appropriate cache headers) to the client
func imageHandler(image []byte, etag string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "image/jpeg")
		w.Header().Set("ETag", etag)
		if r.Header.Get("Cache-Control") != "no-cache" && r.Header.Get("If-None-Match") == etag {
			w.WriteHeader(http.StatusNotModified)
			return
		}
		w.Header().Set("Cache-Control", "public, max-age=300")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(image)
	}
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s", r.Method, r.URL.Path)
		next.ServeHTTP(w, r)
	})
}
