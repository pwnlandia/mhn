// Package auth provides basic authentication and authorization primitives for
// use elsewhere in the application.
// TODO: Maybe move this into auth/jwt
package auth

import (
	"errors"
	"fmt"
	"time"

	jwt "github.com/dgrijalva/jwt-go"
)

// MinBytes is the minimum amount of bytes for secret allowed.
var MinBytes = 32

// ExpiryDuration determines that all tokens expire 24 hours after minting.
var ExpiryDuration = 24 * time.Hour

// ErrSecretTooShort is an signaling the provided secret must be longer.
var ErrSecretTooShort = errors.New("secret length must be at least 32 bytes")

// ErrInvalidToken is returned if the passed in JWT is unable to be parsed by
// the library.
var ErrInvalidToken = errors.New("invalid JWT")

// JWTSecret is the type for holding the signing secret of a JWT.
type JWTSecret struct {
	Secret []byte
}

// Sign takes a role string to be stored in the JWT and signed.
// WARNING: This method is dangerous to call with a cryptographically
// insecure secret.
func (s *JWTSecret) Sign(role string) (string, error) {
	// Make sure token is valid
	err := s.ValidSecret()
	if err != nil {
		return "", err
	}

	// Create a new token object, specifying signing method and the claims
	// you would like it to contain.
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"role": role,
		"iat":  time.Now().Unix(),
		"exp":  time.Now().Add(ExpiryDuration).Unix(),
	})

	// Sign and get the complete encoded token as a string using the secret
	tokenString, err := token.SignedString(s.Secret)
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// ValidateToken takes a token string, usually provided by the user, and
// validates whether or not it is properly signed as well as parses out any claims.
func (s *JWTSecret) ValidateToken(tokenString string) (jwt.MapClaims, error) {
	// Make sure token is valid
	err := s.ValidSecret()
	if err != nil {
		return nil, err
	}

	// Parse takes the token string and a function for looking up/returning the
	// key.
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Don't forget to validate the alg is what you expect
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("Unexpected signing method: %v", token.Header["alg"])
		}

		// hmacSampleSecret is a []byte containing your
		// secret, e.g. []byte("my_secret_key")
		return s.Secret, nil
	})

	if err != nil {
		return nil, err
	}

	// Check if the token is valid and the claims map properly.
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		err = claims.Valid()
		return claims, err
	}
	return nil, ErrInvalidToken
}

// SetSecret allows for the secret of the signer to be set with a copied byte
// slice for safety.
func (s *JWTSecret) SetSecret(secret []byte) {
	buf := make([]byte, len(secret))
	copy(buf, secret)
	s.Secret = buf
}

// ValidSecret returns an error if the secret is not long enough. Must be
// MinBytes long at minimum to be safe.
func (s *JWTSecret) ValidSecret() error {
	// Sanity check that secret is not empty and reasonable length
	if len(s.Secret) < MinBytes {
		return ErrSecretTooShort
	}
	return nil
}
