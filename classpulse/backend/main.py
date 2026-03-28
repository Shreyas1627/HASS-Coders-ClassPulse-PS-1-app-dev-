import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routers import teacher, student

app = FastAPI(title="ClassPulse API")

# CORS — allow all origins for local/demo
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files — Student web interface
app.mount("/student_web", StaticFiles(directory="webpage", html=True), name="student_web")

# Routers
app.include_router(teacher.router, prefix="/api/teacher", tags=["Teacher"])
app.include_router(student.router, prefix="/api/student", tags=["Student"])

@app.get("/")
async def root():
    return {"message": "ClassPulse API is running!", "version": "2.0.0"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)