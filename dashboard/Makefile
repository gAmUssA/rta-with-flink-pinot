# Makefile
include ../make/common.mk

.PHONY: install format lint test coverage dev

install:
	$(call MSG_INFO,Installing dependencies...)
	poetry install
	$(call MSG_SUCCESS,Dependencies installed)

format:
	$(call MSG_INFO,Formatting code...)
	poetry run black src tests
	poetry run isort src tests
	$(call MSG_SUCCESS,Code formatted)

lint:
	$(call MSG_INFO,Running linters...)
	poetry run black --check src tests
	poetry run isort --check-only src tests
	poetry run flake8 src tests
	poetry run mypy src tests
	$(call MSG_SUCCESS,Linting passed)

test:
	$(call MSG_INFO,Running tests...)
	poetry run pytest tests -v
	$(call MSG_SUCCESS,Tests passed)

coverage:
	$(call MSG_INFO,Generating coverage report...)
	poetry run pytest --cov=src --cov-report=term-missing tests
	$(call MSG_SUCCESS,Coverage report generated)

dev:
	$(call MSG_INFO,Starting Streamlit development server...)
	poetry run streamlit run app.py
	$(call MSG_SUCCESS,Streamlit server stopped)

pre-commit:
	poetry run pre-commit run --all-files
