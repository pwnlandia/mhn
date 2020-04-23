package api

import (
	"net/http"
	"strings"

	rbac "github.com/mikespook/gorbac"
	"github.com/pwnlandia/mhn/config"
)

type MiddlewareHandler interface {
	Permission(rbac.Permission, http.HandlerFunc) http.HandlerFunc
}

type middlewareHandler struct {
	cs   config.Service
	rbac *rbac.RBAC
}

func NewMiddlewareHandler(cs config.Service, r *rbac.RBAC) MiddlewareHandler {
	return &middlewareHandler{cs, r}
}

// Permission is a middleware that checks that the request includes an JWT with appropriate permissions for this request.
func (mh *middlewareHandler) Permission(p rbac.Permission, h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// TODO: Swap with Go's stdlib version of parsing this header
		auth := strings.SplitN(r.Header.Get("Authorization"), " ", 2)
		if len(auth) != 2 || auth[0] != "Bearer" {
			// https://tools.ietf.org/html/rfc7235#section-3.1
			w.Header().Set("WWW-Authenticate", "Basic")
			http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
			return
		}

		// auth[1] is the JWT at this point
		// TODO: See what error might be returned, may not want to divulge.
		secret, err := mh.cs.JWTSecret()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		claims, err := secret.ValidateToken(auth[1])
		if err != nil {
			// TODO: See what error might be returned, might not be good to
			// divulge
			w.Header().Set("WWW-Authenticate", "Basic")
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}

		role := claims["role"].(string)
		if !mh.rbac.IsGranted(role, p, nil) {
			http.Error(w, http.StatusText(http.StatusForbidden), http.StatusForbidden)
			return
		}

		h.ServeHTTP(w, r)
	}
}
