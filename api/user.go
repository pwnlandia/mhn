package api

import (
	"github.com/pwnlandia/mhn/auth"
	"github.com/pwnlandia/mhn/model"
	"github.com/pwnlandia/mhn/user"

	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"regexp"

	"github.com/gorilla/mux"
)

var (
	// User's Names should be alphanumeric, allowing "-", "@", ".", "+", and up
	// to 32 characters in length. This allows emails as user names.
	validUserName = regexp.MustCompile(`^[a-zA-Z0-9\-\@\.\+]{1,32}$`)

	// Password can be any non whitespace character, at least 6 chars long.
	validUserPassword = regexp.MustCompile(`\S{6,}`)

	// ErrInvalidUserName gives info to what a valid username should look like.
	ErrInvalidUserName = errors.New("User's Names must only be alphanumeric or include -, @, ., + and be up to 32 characters in length")
	// ErrInvalidUserPassword shows what a valid password should consist of.
	ErrInvalidUserPassword = errors.New("Password must be at least 6 characters long and not include whitespace")
	// ErrInvalidUserRole simply tells whether a role exists or not.
	ErrInvalidUserRole = errors.New("Role does not exist")
)

type UserHandler interface {
	Get() http.HandlerFunc
	Put() http.HandlerFunc
	Delete() http.HandlerFunc
}

type userHandler struct {
	us user.Service
}

func NewUserHandler(us user.Service) UserHandler {
	return &userHandler{us}
}

// UserReq is used for parsing API input
type UserReq struct {
	Name     string
	Password string
	Role     string
}

// UserResp is used for exporting User data via API responses
type UserResp struct {
	Name string
	Role string
}

// validateUserReq checks that all fields follow a valid format and that the RBAC
// role actually exists.
func validateUserReq(u *UserReq) error {
	if !validUserName.MatchString(u.Name) {
		return ErrInvalidUserName
	}

	if !validUserPassword.MatchString(u.Password) {
		return ErrInvalidUserPassword
	}

	if !auth.ValidRole(u.Role) {
		return ErrInvalidUserRole
	}

	return nil
}

func (h *userHandler) Delete() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		id := vars["id"]

		// DELETE /api/user/
		// Delete all users
		if id == "" {
			err := h.us.DeleteAllUsers()
			if err != nil {
				log.Printf("apiIdentDELETEHandler, DeleteAllIdentities(), %s", err.Error())
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			w.WriteHeader(http.StatusNoContent)
			return
		}

		// Delete user
		u, err := h.us.GetUser(id)
		if err != nil {
			log.Printf("apiUserDELETEHandler, GetUser(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// If it doesn't already exist, return 404.
		if u == nil {
			w.WriteHeader(http.StatusNotFound)
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}

		err = h.us.DeleteUser(id)
		if err != nil {
			log.Printf("apiUserDELETEHandler, DeleteUser(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusNoContent)
		return
	}

}

func (h *userHandler) Get() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		id := vars["id"]

		// TODO: Factor out this section into new handler perhaps.
		// "/api/user/"
		if id == "" {
			users, err := h.us.GetAllUsers()
			if err != nil {
				log.Printf("apiUserGETHandler, GetAllUsers(), %s", err.Error())
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			var urs []*UserResp
			for _, u := range users {
				ur := &UserResp{Name: u.Name, Role: u.Role}
				urs = append(urs, ur)
			}

			w.WriteHeader(http.StatusOK)
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(urs)
			return
		}

		// Return user if found
		u, err := h.us.GetUser(id)
		if err != nil {
			log.Printf("apiUserGETHandler, GetUser(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		if u == nil {
			http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
			return
		}

		// Make an appropriate response object (ie. no hash returned)
		ur := &UserResp{Name: u.Name, Role: u.Role}
		buf, err := json.Marshal(ur)
		if err != nil {
			log.Printf("apiUserGETHandler, json.Marshal(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, "%s", buf)
	}
}

func (h *userHandler) Put() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var create bool

		vars := mux.Vars(r)
		id := vars["id"]

		// Can't PUT on /user/ without an identifier.
		if id == "" {
			http.Error(w, ErrMissingID.Error(), http.StatusBadRequest)
			return
		}

		// Check to see if this user name already exists
		u, err := h.us.GetUser(id)
		if err != nil {
			log.Printf("apiUserPUTHandler, GetIdentity(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Is this a new User being created?
		// We want to remember so we know to return 200 vs 201
		if u == nil {
			create = true
		}

		if r.Body == nil {
			http.Error(w, ErrBodyRequired.Error(), http.StatusBadRequest)
			return
		}

		// Decode JSON payload
		ureq := &UserReq{}
		err = json.NewDecoder(r.Body).Decode(ureq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		// Make sure payload username matches ID in URI
		if id != ureq.Name {
			http.Error(w, ErrMismatchedID.Error(), http.StatusBadRequest)
			return
		}

		// Make sure all fields are valid.
		err = validateUserReq(ureq)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		// Create new User obj.
		u, err = model.NewUser(ureq.Name, ureq.Password, ureq.Role)
		if err != nil {
			log.Printf("apiUserPUTHandler, NewUser(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Save to database
		err = h.us.SaveUser(u)
		if err != nil {
			log.Printf("apiUserPUTHandler, SaveUser(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Build a response obj to return, specifically leaving out
		// Password/Hash
		uresp := &UserResp{Name: u.Name, Role: u.Role}
		out, err := json.Marshal(uresp)
		if err != nil {
			log.Printf("apiUserPUTHandler, json.Marshal(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// If new user, create, if existing, we're updating so return status OK.
		if create {
			w.WriteHeader(http.StatusCreated)
		} else {
			w.WriteHeader(http.StatusOK)
		}

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, "%s", out)
	}
}
