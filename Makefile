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

stop:
	@echo "Stopping and removing containers..."
	@docker-compose -f srcs/docker-compose.yml down

clean: stop

fclean: clean
	@echo "Removing data directories..."
	@rm -rf data

.PHONY: all dirs build up down clean fclean
