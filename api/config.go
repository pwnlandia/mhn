package api

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/pwnlandia/mhn/config"
	"github.com/pwnlandia/mhn/service"
)

// ConfigHandler provides endpoints for all api/config/ calls.
// TODO: Add RESET for JWT secret.
// TODO: Change this to a "Handle" func only, abstract from there.
type ConfigHandler interface {
	SuperAdmin() http.HandlerFunc
}

type configHandler struct {
	cs config.Service
}

// NewConfigHandler takes a config.Service and returns a working ConfigHandler.
func NewConfigHandler(cs config.Service) ConfigHandler {
	return &configHandler{cs}
}

type saReq struct {
	Name string
}

type saResp struct {
	Name     string
	Role     string
	Password string
}

// SuperAdmin responds to the api/config/superadmin endpoint.
func (h *configHandler) SuperAdmin() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		vars := mux.Vars(r)
		id := vars["id"]

		// Can't PUT on /config/superadmin/ without an identifier.
		if id == "" {
			http.Error(w, ErrMissingID.Error(), http.StatusBadRequest)
			return
		}

		// Try and create new SA
		u, p, err := h.cs.CreateSuperAdmin(id)
		if err != nil {
			log.Printf("SuperAdmin, CreateSuperAdmin(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if err == service.ErrSuperAdminExists {
			http.Error(w, err.Error(), http.StatusConflict)
			return
		}
		if err != nil {
			// TODO: Confirm error case here is Server Error.
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Build a response obj to return specifically WITH password
		resp := &saResp{Name: u.Name, Role: u.Role, Password: p}
		out, err := json.Marshal(resp)
		if err != nil {
			log.Printf("SuperAdmin, json.Marshal(), %s", err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusCreated)

		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, "%s", out)
	}
}
