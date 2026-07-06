package microservice_test

import (
	"context"
	"crypto/tls"
	"fmt"
	"os"
	"testing"

	redis "github.com/go-redis/redis/v8"
)

func TestRedisClientConnect(t *testing.T) {
	redisAddr := os.Getenv("REDIS_URI")
	if redisAddr == "" {
		t.Skip("REDIS_URI is not set")
	}

	// new redis client

	client := redis.NewClient(&redis.Options{

		Addr:     redisAddr,
		Username: "default",
		Password: os.Getenv("REDIS_PASSWORD"),

		DB: 1,
		TLSConfig: &tls.Config{
			MinVersion: tls.VersionTLS12,
		},
	})

	// test connection

	pong, err := client.Ping(context.TODO()).Result()

	if err != nil {

		t.Error(err)

	}

	// return pong if server is online

	fmt.Println(pong)
}
