package dao

import (
	"fmt"
	"hr-board/conf"
	"hr-board/dao/cache"
	"hr-board/dao/postgres"
)

type (
	DAO interface {
		Postgres
		Cache
	}

	Postgres interface{}

	Cache   interface{}
	daoImpl struct {
		*postgres.Postgres
		*cache.Cache
	}
)

func New(cfg conf.Config) (DAO, error) {
	pg, err := postgres.NewPostgres(cfg.Postgres)
	if err != nil {
		return nil, fmt.Errorf("postgres.NewPostgres: %s", err.Error())
	}
	return daoImpl{
		Postgres: pg,
		Cache:    cache.NewCache(pg),
	}, nil
}
