package utils

import (
	"bytes"
	"encoding/base64"
	"fmt"
	"math/rand"
	"os"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/gin-gonic/gin"
)

// ParseSignedPayload parses payload, returns respectively message and signature
func ParseSignedPayload(p []byte) (string, []byte, error) {
	splitted := strings.SplitN(string(p), ".", 2)
	if len(splitted) < 1 {
		return "", nil, fmt.Errorf("payload is invalid, it should contain payload and signature")
	}
	signature := splitted[0]
	decoded, err := base64.StdEncoding.DecodeString(signature)
	if err != nil {
		return "", nil, fmt.Errorf("failed parsing signature %s", err.Error())
	}
	payload := splitted[1]

	return payload, decoded, nil
}

// GenerateRandomString generates random string and returns it
func GenerateRandomString(length int) string {
	rand.Seed(time.Now().UnixNano())
	chars := []rune("ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
		"abcdefghijklmnopqrstuvwxyz" +
		"0123456789")
	var b strings.Builder
	for i := 0; i < length; i++ {
		b.WriteRune(chars[rand.Intn(len(chars))])
	}
	return b.String()
}

// HashPassword hashes password with bcrypt
func HashPassword(pass []byte) ([]byte, error) {
	return bcrypt.GenerateFromPassword(pass, bcrypt.DefaultCost)
}

// ComparePasswordAndHash checks hash of password, returns true if they match, otherwise false
func ComparePasswordAndHash(password, hash []byte) bool {
	err := bcrypt.CompareHashAndPassword(hash, password)
	return err == nil
}

// MustGetEnv retreives the enviroment variable
//
// Panics if doesn't exists
func MustGetEnv(key string) string {
	env, present := os.LookupEnv(key)
	if !present {
		panic(fmt.Errorf("%s enviroment variable is unset", key))
	}
	return env
}

type responseBodyWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (r responseBodyWriter) Write(b []byte) (int, error) {
	r.body.Write(b)
	return r.ResponseWriter.Write(b)
}

// LogResponseBody is middleware for Gin to log response
func LogResponseBody(c *gin.Context) {
	w := &responseBodyWriter{body: &bytes.Buffer{}, ResponseWriter: c.Writer}
	c.Writer = w
	c.Next()
	fmt.Println("Response body: " + w.body.String())
}
