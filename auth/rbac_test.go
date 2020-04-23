package auth

import (
	"testing"
)

func Test_RBAC(t *testing.T) {
	r := InitRBAC()

	t.Run("InitRBAC", func(t *testing.T) {

		t.Run("User Reader", func(t *testing.T) {
			if !r.IsGranted(RoleUserReader, PermUserRead, nil) {
				t.Error("User Reader must be able to read")
			}
			if r.IsGranted(RoleUserReader, PermUserWrite, nil) {
				t.Error("User Reader must not be able to write")
			}
		})

		t.Run("User Admin", func(t *testing.T) {
			if !r.IsGranted(RoleUserAdmin, PermUserRead, nil) {
				t.Error("User Admin must be able to read")
			}
			if !r.IsGranted(RoleUserAdmin, PermUserWrite, nil) {
				t.Error("User Admin must be able to write")
			}
		})

		t.Run("Super Admin", func(t *testing.T) {
			if !r.IsGranted(RoleSuperAdmin, PermUserRead, nil) {
				t.Error("Super Admin must be able to read users")
			}
			if !r.IsGranted(RoleSuperAdmin, PermUserWrite, nil) {
				t.Error("Super Admin must be able to write users")
			}
		})
	})

	t.Run("ValidRole", func(t *testing.T) {
		if !ValidRole(RoleUserReader) || !ValidRole(RoleUserAdmin) {
			t.Error("Valid role not found to be valid")
		}

		if !ValidRole(RoleSuperAdmin) {
			t.Error("Valid role not found to be valid")
		}

		if ValidRole("totally_not_valid") {
			t.Error("Invalid role found to be valid")
		}
	})
}
