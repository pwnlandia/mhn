package auth

import (
	"testing"
)

func TestSign(t *testing.T) {
	t.Run("Bad Secret", func(t *testing.T) {
		s := JWTSecret{Secret: []byte{0x00}}
		_, err := s.Sign("test")
		if err == nil {
			t.Error("Expected error for bad signer secret")
		}
		if err != ErrSecretTooShort {
			t.Errorf("Expected ErrSecretTooShort, got: %s", err.Error())
		}
	})

	t.Run("Good Secret", func(t *testing.T) {
		s := &JWTSecret{}
		s.SetSecret([]byte{
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
		})

		token, err := s.Sign("test")
		if err != nil {
			t.Errorf("Error creating token: %s", err)
		}

		// TODO: Add a token using a SigningMethod that is NOT HMAC, we
		// especially want to add a test for NO signing method that MUST fail.
		// TODO: Add test to make sure ValidateToken tests ValidSecret as well.
		// TODO: Add test with a completely invalid token to trigger ErrInvalidToken.
		claims, err := s.ValidateToken(token)
		if err != nil {
			t.Errorf("Error validating token: %s", err)
		}

		// Cast role to string
		r := claims["role"].(string)
		if "test" != r {
			t.Error("Role claimed does not match")
		}

		s2 := JWTSecret{
			Secret: []byte{
				0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
			},
		}

		_, err = s2.ValidateToken(token)
		if err == nil {
			t.Error("Expected error with validation from wrong key")
		}

	})

}
