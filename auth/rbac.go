package auth

import (
	"github.com/mikespook/gorbac"
)

// Create separate read and write permissions
var (
	// Permission for reading app users
	PermUserRead = gorbac.NewStdPermission("user_read")
	// Permissions for editing app users
	PermUserWrite = gorbac.NewStdPermission("user_write")

	PermChallengeAdmin = gorbac.NewStdPermission("challenge")

	PermCertAdmin = gorbac.NewStdPermission("cert")

	// Role that has User Read permission
	RoleUserReader = "user_reader"
	// Role that has User Write and Read permissions
	RoleUserAdmin = "user_admin"

	// Role that will have all permissions.
	RoleSuperAdmin = "super_admin"
)

// InitRBAC returns a new instance of gorbac.RBAC for Role-Based Access Controls.
func InitRBAC() *gorbac.RBAC {
	r := gorbac.New()

	// Basic READ for app users
	rur := gorbac.NewStdRole(RoleUserReader)
	rur.Assign(PermUserRead)
	r.Add(rur)

	// Read and write for app users
	rua := gorbac.NewStdRole(RoleUserAdmin)
	rua.Assign(PermUserRead)
	rua.Assign(PermUserWrite)
	r.Add(rua)

	// Super admin inherits all roles
	rsa := gorbac.NewStdRole(RoleSuperAdmin)
	rsa.Assign(PermChallengeAdmin)
	rsa.Assign(PermCertAdmin)
	r.Add(rsa)
	r.SetParents(RoleSuperAdmin, []string{RoleUserAdmin})

	return r
}

// ValidRole takes a string and compares it to a list of valid rules. Returns
// true if there is a match.
// TODO: Make map for faster lookup.
func ValidRole(r string) bool {
	roles := []string{
		RoleUserReader,
		RoleUserAdmin,
		RoleSuperAdmin,
	}

	for _, role := range roles {
		if r == role {
			return true
		}
	}

	return false
}
