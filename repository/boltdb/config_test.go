package boltdb

import (
	"bytes"
	"testing"

	"github.com/boltdb/bolt"
	"github.com/pwnlandia/mhn/config"
)

func TestConfigRepository(t *testing.T) {
	db, err := bolt.Open(TestDBPath, 0666, nil)
	if err != nil {
		t.Fatalf("Error opening test db: %s", err.Error())
	}
	defer db.Close()

	var r config.Repository
	t.Run("NewConfigRespository", func(t *testing.T) {
		r, err = NewConfigRepository(db)
		if err != nil {
			t.Fatalf("Error on NewConfigRepository: %s", err.Error())
		}
	})

	t.Run("JWTSecret", func(t *testing.T) {
		t.Run("Set", func(t *testing.T) {
			s := []byte{0xDE, 0xAD, 0xBE, 0xEF}
			err := r.SetJWTSecret(s)
			if err != nil {
				t.Errorf("Unexpected error setting secret %s", err.Error())
			}

		})

		t.Run("Get", func(t *testing.T) {
			s, err := r.JWTSecret()
			if err != nil {
				t.Errorf("Unexpected error getting secret %s", err.Error())
			}

			if !bytes.Equal(s.Secret, []byte{0xDE, 0xAD, 0xBE, 0xEF}) {
				t.Error("Unexpected secret retrieved from DB.")
			}
		})
	})

}
