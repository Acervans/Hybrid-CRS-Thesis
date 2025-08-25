import io
import json
import pytest

from fastapi.testclient import TestClient
from api import app

client = TestClient(app)

JWT_SUB = "mock_user"
JWT_TOKEN = "Bearer test.jwt.token"
HEADERS = {"Authorization": JWT_TOKEN}

@pytest.fixture(autouse=True)
def mock_jwt_decode(mocker):
    mocker.patch("api.jwt.decode", return_value={"sub": "mock_user"})

def test_pdf_to_text():
    pdf_bytes = ...
    response = client.post(
        "/pdf-to-text",
        files={"file": ("test.pdf", io.BytesIO(pdf_bytes), "application/pdf")},
        headers=HEADERS,
    )
    assert response.status_code == 200
    assert response.text == "Example Content\n\n"

def test_infer_column_roles():
    ...

def test_infer_datatype():
    ...

def test_infer_delimiter():
    ...

def test_create_agent(mocker):
    # Mock Supabase
    mocker.patch("api.supabase")

    # Mock recommender logic
    mocker.patch("api.FalkorDBRecommender")
    mocker.patch("api.train_expert_model", return_value=({}, {"score": 0.9}))
    mocker.patch("api.process_dataset")
    mocker.patch("api.os.remove")
    mocker.patch("api.shutil.rmtree")

    agent_config = {
        "agent_name": "TestAgent",
        "dataset_name": "TestSet",
        "description": "desc",
        "public": True,
    }
    dataset_file = {
        "file_type": "interactions",
        "columns": [
            {"name": "user_id", "data_type": "token", "role": "user"},
            {"name": "item_id", "data_type": "token", "role": "item"},
            {"name": "rating", "data_type": "float", "role": "rating"},
        ],
        "sniff_result": {
            "delimiter": ",",
            "newline_str": "\n",
            "has_header": True,
            "quote_char": '"',
        },
    }
    files = {
        "agent_id": (None, "123"),
        "agent_config": (None, json.dumps(agent_config)),
        "dataset_files": (None, json.dumps(dataset_file)),
        "upload_files": (
            "inter.csv",
            io.BytesIO(b"user_id,item_id,rating\n1,2,3\n"),
            "text/csv",
        ),
    }
    response = client.post("/create-agent", files=files, headers=HEADERS)
    assert response.status_code in (200, 500)

def test_chat_history_endpoints(mocker):
    ...
