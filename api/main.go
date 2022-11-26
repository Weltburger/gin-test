package api

import (
	"context"
	"fmt"
	"net/http"
	"reflect"
	"strconv"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/gorilla/schema"
	"github.com/urfave/negroni"
	"go.uber.org/zap"
	"google.golang.org/api/option"
	"hr-board/conf"
	"hr-board/helpers/null"
	"hr-board/log"
	"hr-board/services"
)

const (
	firebaseFilePath = "./firebase-auth.json"
	userContextKey   = "user"
)

type (
	API struct {
		router       *gin.Engine
		server       *http.Server
		cfg          conf.Config
		services     services.Service
		queryDecoder *schema.Decoder
		auth         *auth.Client
	}

	// Route stores an API route data
	Route struct {
		Path       string
		Method     string
		Func       func(http.ResponseWriter, *http.Request)
		Middleware []negroni.HandlerFunc
	}
)

func NewAPI(cfg conf.Config, s services.Service) (*API, error) {
	queryDecoder := schema.NewDecoder()
	queryDecoder.IgnoreUnknownKeys(true)
	queryDecoder.RegisterConverter(null.Time{}, func(s string) reflect.Value {
		timestamp, err := strconv.ParseInt(s, 10, 64)
		if err != nil {
			return reflect.Value{}
		}
		t := null.NewTime(time.Unix(timestamp, 0))
		return reflect.ValueOf(t)
	})
	api := &API{
		cfg:          cfg,
		services:     s,
		queryDecoder: queryDecoder,
	}
	err := api.setFirebaseAuth()
	if err != nil {
		return nil, fmt.Errorf("api.setFirebaseAuth: %s", err.Error())
	}
	api.initialize()
	return api, nil
}

// Run starts the http server and binds the handlers.
func (api *API) Run() error {
	return api.startServe()
}

func (api *API) Stop() error {
	return api.server.Shutdown(context.Background())
}

func (api *API) Title() string {
	return "API"
}

func (api *API) initialize() {
	api.router = gin.Default()

	// By default gin.DefaultWriter = os.Stdout
	api.router.Use(gin.Logger())

	// Recovery middleware recovers from any panics and writes a 500 if there was one.
	api.router.Use(gin.Recovery())

	api.router.Use(cors.New(cors.Config{
		AllowOrigins:     api.cfg.API.CORSAllowedOrigins,
		AllowCredentials: true,
		AllowMethods: []string{
			http.MethodPost, http.MethodHead, http.MethodGet, http.MethodOptions, http.MethodPut, http.MethodDelete,
		},
		AllowHeaders: []string{
			"Accept", "Content-Type", "Content-Length", "Accept-Encoding", "X-CSRF-Token",
			"Authorization", "User-Env", "Access-Control-Request-Headers", "Access-Control-Request-Method",
		},
	}))

	// public routes
	api.router.GET("/", api.Index)
	api.router.GET("/health", api.Health)

	mGroup := api.router.Group("/m")
	mGroup.Use(api.SomeMiddleware())
	{
		mGroup.POST("/name", api.Name)
		mGroup.GET("/read/:id", api.Read)
	}
	api.server = &http.Server{Addr: fmt.Sprintf(":%d", api.cfg.API.ListenOnPort), Handler: api.router}
}

func (api *API) startServe() error {
	log.Info("Start listening server on port", zap.Uint64("port", api.cfg.API.ListenOnPort))
	err := api.server.ListenAndServe()
	if err == http.ErrServerClosed {
		log.Warn("API server was closed")
		return nil
	}
	if err != nil {
		return fmt.Errorf("cannot run API service: %s", err.Error())
	}
	return nil
}

func (api *API) setFirebaseAuth() error {
	opt := option.WithCredentialsFile(firebaseFilePath)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return fmt.Errorf("firebase.NewApp: %s", err.Error())
	}
	api.auth, err = app.Auth(context.Background())
	if err != nil {
		return fmt.Errorf("app.Auth: %s", err.Error())
	}
	return nil
}
