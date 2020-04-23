package boltdb

import (
	"testing"

	"github.com/pwnlandia/mhn/model"
)

const TestDBPath = ".test.db"

func assertEqualUser(t *testing.T, expect *model.User, got *model.User) {
	t.Helper()
	if expect.Name != got.Name {
		t.Errorf("Mismatched Names:\n\tgot %s \n\twant %s", got.Name, expect.Name)
	}
	if expect.Hash != got.Hash {
		t.Errorf("Mismatched Hashes:\n\tgot %s \n\twant %s", got.Hash, expect.Hash)
	}
	if expect.Role != got.Role {
		t.Errorf("Mismatched Roles:\n\tgot %s \n\twant %s", got.Role, expect.Role)
	}
}

func testEq(a, b []string) bool {
	// If one is nil, the other must also be nil.
	if (a == nil) != (b == nil) {
		return false
	}

	if len(a) != len(b) {
		return false
	}

	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}

	return true
}
