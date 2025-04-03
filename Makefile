all: dirs build

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

down:
	@echo "Stopping and removing containers..."
	@docker-compose -f srcs/docker-compose.yml down

clean:
	@echo "Cleaning up containers and images..."
	@docker-compose -f srcs/docker-compose.yml down --rmi all

fclean: clean
	@echo "Removing data directory..."

.PHONY: all dirs build up down clean fclean
