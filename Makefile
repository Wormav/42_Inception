DATA_DIR=~/data

# Vérifie si les conteneurs sont en cours d'exécution
containers_running = $(shell docker ps -q)

all: dirs build start

start_docker:
	@echo "Starting Docker service..."
	@open --background -a Docker
	@while ! docker system info > /dev/null 2>&1; do \
        echo "Waiting for Docker to start..."; \
        sleep 1; \
	done
	@echo "Docker is running."

dirs:
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress
	@mkdir -p $(DATA_DIR)/adminer
	@sudo chmod -R 755 $(DATA_DIR)
	@echo "Created data directories at $(DATA_DIR)"

build:
	@if [ -z "$(containers_running)" ]; then \
		echo "Building images..."; \
		docker compose -f srcs/docker-compose.yml build; \
	else \
		echo "Containers are already running. Skipping build."; \
	fi

start:
	@echo "Starting containers..."
	@docker compose -f srcs/docker-compose.yml up -d

stop:
	@echo "Stopping and removing containers..."
	@docker compose -f srcs/docker-compose.yml down

stop_docker:
	@echo "Stopping Docker service..."
	@osascript -e 'quit app "Docker"'
	@echo "Docker has been stopped."

re: start

clean: stop

fclean: clean
	@echo "Removing data directories at $(DATA_DIR)..."
	@sudo rm -rf $(DATA_DIR)

.PHONY: all start_docker stop_docker dirs build start stop clean fclean

