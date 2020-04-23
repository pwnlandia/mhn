package model

import (
	"testing"
)

func TestUser(t *testing.T) {
	t.Run("NewUser", func(t *testing.T) {
		u, err := NewUser("name1", "pass1", "role1")
		if err != nil {
			t.Fatal(err)
		}

		if u == nil {
			t.Fatal("User should not be nil")
		}
	})

	t.Run("ComparePasswordAndHash", func(t *testing.T) {
		u, _ := NewUser("name1", "pass1", "role1")

		m, err := u.ComparePasswordAndHash("wrong")
		if err != nil {
			t.Fatal(err)
		}
		if m == true {
			t.Error("Comparison should have failed")
		}

		m, err = u.ComparePasswordAndHash("pass1")
		if err != nil {
			t.Fatal(err)
		}
		if m != true {
			t.Error("Comparison should have succeeded")
		}
	})

	t.Run("SetPassword", func(t *testing.T) {
		u, _ := NewUser("name1", "pass1", "role1")

		m, err := u.ComparePasswordAndHash("pass1")
		if err != nil {
			t.Fatal(err)
		}
		if m != true {
			t.Error("Comparison should have succeeded")
		}

		u.SetPassword("pass2")
		m, err = u.ComparePasswordAndHash("pass2")
		if err != nil {
			t.Fatal(err)
		}
		if m != true {
			t.Error("Comparison should have succeeded")
		}
	})
}
