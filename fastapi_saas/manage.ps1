param (
    [string]$Command
)

switch ($Command) {
    "up" { docker-compose up -d }
    "down" { docker-compose down }
    "test" { docker-compose exec fastapi pytest }
    "migrate" { docker-compose exec fastapi alembic upgrade head }
    "shell" { docker-compose exec fastapi python }
    Default {
        Write-Host "Usage: .\manage.ps1 [up|down|test|migrate|shell]"
        Write-Host "  up      - Start services"
        Write-Host "  down    - Stop services"
        Write-Host "  test    - Run tests"
        Write-Host "  migrate - Run DB migrations"
        Write-Host "  shell   - Open Python shell"
    }
}
