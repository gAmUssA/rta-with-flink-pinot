# Makefile
.PHONY: install format lint test coverage

install:
	poetry install

format:
	poetry run black src tests
	poetry run isort src tests

lint:
	poetry run flake8 src tests
	poetry run mypy src tests
	poetry run black --check src tests
	poetry run isort --check-only src tests

test:
	poetry run pytest

coverage:
	poetry run pytest --cov=src --cov-report=xml

pre-commit:
	poetry run pre-commit run --all-files