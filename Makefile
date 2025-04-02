all: dirs build

dirs:
	@mkdir -p data/mariadb
	@mkdir -p data/wordpress
	@echo "Created data directories"

build:
	@echo "Building images..."
	@docker-compose -f srcs/docker-compose.yml build

up:
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
	@rm -rf data/

prune:
	@echo "Pruning entire Docker system..."
	@docker system prune -af

.PHONY: all dirs build up down clean fclean prune
