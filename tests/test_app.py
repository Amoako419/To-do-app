import pytest
from app.app import app, db, User, Todo
from werkzeug.security import generate_password_hash

@pytest.fixture
def client():
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    app.config['TESTING'] = True
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.session.remove()
            db.drop_all()

@pytest.fixture
def auth_client(client):
    with app.app_context():
        username = "testuser"
        password = "testpass"
        user = User(username=username, password_hash=generate_password_hash(password))
        db.session.add(user)
        db.session.commit()
        
    response = client.post('/login', data={'username': username, 'password': password})
    return client

def test_signup(client):
    response = client.post('/signup', data={
        'username': 'newuser',
        'password': 'newpass'
    }, follow_redirects=True)
    assert response.status_code == 200
    with app.app_context():
        user = User.query.filter_by(username='newuser').first()
        assert user is not None

def test_login_logout(client):
    # Create a test user
    client.post('/signup', data={
        'username': 'testuser',
        'password': 'testpass'
    })
    
    # Test login
    response = client.post('/login', data={
        'username': 'testuser',
        'password': 'testpass'
    }, follow_redirects=True)
    assert response.status_code == 200
    
    # Test logout
    response = client.get('/logout', follow_redirects=True)
    assert response.status_code == 200

def test_add_todo(auth_client):
    response = auth_client.post('/add', data={
        'title': 'Test Todo',
        'description': 'Test Description'
    }, follow_redirects=True)
    assert response.status_code == 200
    with app.app_context():
        todo = Todo.query.filter_by(title='Test Todo').first()
        assert todo is not None
        assert todo.description == 'Test Description'

def test_complete_todo(auth_client):
    # First add a todo
    auth_client.post('/add', data={
        'title': 'Test Todo',
        'description': 'Test Description'
    })
    
    todo_id = None
    with app.app_context():
        todo = Todo.query.filter_by(title='Test Todo').first()
        todo_id = todo.id
        
    response = auth_client.get(f'/complete/{todo_id}', follow_redirects=True)
    assert response.status_code == 200
    
    with app.app_context():
        todo = Todo.query.get(todo_id)
        assert todo.completed == True

def test_delete_todo(auth_client):
    # First add a todo
    auth_client.post('/add', data={
        'title': 'Test Todo',
        'description': 'Test Description'
    })
    
    todo_id = None
    with app.app_context():
        todo = Todo.query.filter_by(title='Test Todo').first()
        todo_id = todo.id
        
    response = auth_client.get(f'/delete/{todo_id}', follow_redirects=True)
    assert response.status_code == 200
    
    with app.app_context():
        deleted_todo = Todo.query.get(todo_id)
        assert deleted_todo is None