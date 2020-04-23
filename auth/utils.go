package auth

import (
	"crypto/rand"
	"encoding/base64"
	"log"
)

// randBytes is the number of bytes of entropy for SA password
const randBytes = 16

// NewPassword generates cryptographically secure random bytes, base64
// encodes it, and returns it.
func NewPassword() string {
	c := randBytes
	b := make([]byte, c)
	_, err := rand.Read(b)
	if err != nil {
		log.Fatal(err)
	}
	pass := base64.RawURLEncoding.EncodeToString(b)
	return pass
}
