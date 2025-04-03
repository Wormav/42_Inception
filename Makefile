all: start_docker dirs build start

start_docker:
	@echo "Starting Docker service..."
	@open --background -a Docker
	@while ! docker system info > /dev/null 2>&1; do \
        echo "Waiting for Docker to start..."; \
        sleep 1; \
	done
	@echo "Docker is running."

dirs:
	@mkdir -p data/mariadb
	@mkdir -p data/wordpress
	@mkdir -p data/adminer
	@echo "Created data directories"

build:
	@echo "Building images..."
	@docker-compose -f srcs/docker-compose.yml build

start:
	@echo "Starting containers..."
	@docker-compose -f srcs/docker-compose.yml up -d

stop:
	@echo "Stopping and removing containers..."
	@docker-compose -f srcs/docker-compose.yml down

stop_docker:
	@echo "Stopping Docker service..."
	@osascript -e 'quit app "Docker"'
	@echo "Docker has been stopped."

clean: stop

fclean: clean stop_docker
	@echo "Removing data directories..."
	@rm -rf data

.PHONY: all start_docker stop_docker dirs build start stop clean fclean
