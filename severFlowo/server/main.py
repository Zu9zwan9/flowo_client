import os
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from server.api.router import api_router
from server.core.auth import get_api_key

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(
    title="Flowo Task API",
    description="API for task breakdown and estimation using HuggingFace models",
    version="1.0.0",
)

# Add CORS middleware (allow all origins for development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router with API key dependency
app.include_router(
    api_router,
    prefix="/api",
    dependencies=[Depends(get_api_key)],
)

# Health check endpoint (no authentication required)
@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("server.main:app", host="0.0.0.0", port=port, reload=True)