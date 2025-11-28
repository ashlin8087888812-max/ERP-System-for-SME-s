from app.db.base import Base, engine
from app.db import models

# Create all tables
Base.metadata.create_all(bind=engine)
print("All tables created successfully!")
