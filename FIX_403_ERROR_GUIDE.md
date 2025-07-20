# 🔧 Fix 403 Error in Django Backend

## 🚨 **Problem**
Getting 403 Forbidden error when trying to register users from the Flutter mobile app.

## 🔍 **Root Causes**
1. **CORS (Cross-Origin Resource Sharing)** not configured
2. **CSRF (Cross-Site Request Forgery)** protection blocking requests
3. **Django REST Framework permissions** incorrectly set
4. **Missing authentication endpoints**

---

## ✅ **SOLUTION 1: Configure CORS in Django**

### **1. Install django-cors-headers**
```bash
cd backend
pip install django-cors-headers
```

### **2. Update settings.py**
Add to your `backend/settings.py`:

```python
# Add to INSTALLED_APPS
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',  # Add this
    # ... your other apps
]

# Add to MIDDLEWARE (at the top)
MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # Add this at the top
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# CORS Configuration
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://192.168.77.6:3000",
]

# For development, you can use this (less secure)
CORS_ALLOW_ALL_ORIGINS = True

# Allow credentials
CORS_ALLOW_CREDENTIALS = True

# Allow specific headers
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]
```

---

## ✅ **SOLUTION 2: Configure Django REST Framework**

Add to your `settings.py`:

```python
# REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
}

# For registration endpoint, allow unauthenticated access
```

---

## ✅ **SOLUTION 3: Create Authentication Views**

Create `backend/authentication/views.py`:

```python
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
import json

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """Register a new user"""
    try:
        data = json.loads(request.body)
        
        # Extract user data
        email = data.get('email')
        password = data.get('password')
        first_name = data.get('first_name', '')
        last_name = data.get('last_name', '')
        
        # Validate required fields
        if not email or not password:
            return Response({
                'error': 'Email and password are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user already exists
        if User.objects.filter(email=email).exists():
            return Response({
                'error': 'User with this email already exists'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create user
        user = User.objects.create_user(
            username=email,  # Use email as username
            email=email,
            password=password,
            first_name=first_name,
            last_name=last_name
        )
        
        return Response({
            'message': 'User created successfully',
            'user_id': user.id
        }, status=status.HTTP_201_CREATED)
        
    except json.JSONDecodeError:
        return Response({
            'error': 'Invalid JSON data'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """Login user and return token"""
    try:
        data = json.loads(request.body)
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return Response({
                'error': 'Email and password are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Authenticate user
        user = authenticate(username=email, password=password)
        
        if user:
            # Get or create token
            token, created = Token.objects.get_or_create(user=user)
            
            return Response({
                'access': token.key,
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'first_name': user.first_name,
                    'last_name': user.last_name,
                }
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'error': 'Invalid credentials'
            }, status=status.HTTP_401_UNAUTHORIZED)
            
    except json.JSONDecodeError:
        return Response({
            'error': 'Invalid JSON data'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def get_user_profile(request):
    """Get current user profile"""
    return Response({
        'id': request.user.id,
        'email': request.user.email,
        'first_name': request.user.first_name,
        'last_name': request.user.last_name,
    })
```

---

## ✅ **SOLUTION 4: Configure URLs**

Create `backend/authentication/urls.py`:

```python
from django.urls import path
from . import views

urlpatterns = [
    path('register/', views.register_user, name='register'),
    path('login/', views.login_user, name='login'),
    path('user/', views.get_user_profile, name='user-profile'),
]
```

Update your main `backend/urls.py`:

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('authentication.urls')),
    # ... your other URLs
]
```

---

## ✅ **SOLUTION 5: Test the Fix**

### **1. Restart Django Server**
```bash
cd backend
python manage.py runserver 192.168.77.6:8000
```

### **2. Test Registration Endpoint**
```bash
curl -X POST http://192.168.77.6:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

### **3. Test Login Endpoint**
```bash
curl -X POST http://192.168.77.6:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123"
  }'
```

---

## 🔧 **TROUBLESHOOTING**

### **If still getting 403:**

1. **Check Django logs** for detailed error messages
2. **Disable CSRF temporarily** (for testing only):
   ```python
   # In settings.py
   CSRF_TRUSTED_ORIGINS = [
       'http://192.168.77.6:8000',
   ]
   ```

3. **Check if authentication app is installed**:
   ```python
   INSTALLED_APPS = [
       # ...
       'authentication',  # Make sure this is added
   ]
   ```

4. **Run migrations**:
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

---

## 🎯 **Expected Result**

After implementing these fixes:
- ✅ Registration should return 201 status
- ✅ Login should return 200 status with token
- ✅ No more 403 errors
- ✅ Mobile app can successfully register and login users

The mobile app will now be able to register and authenticate users properly!
