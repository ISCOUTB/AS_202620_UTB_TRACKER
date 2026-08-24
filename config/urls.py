from django.contrib import admin
from django.urls import path

from apps.core.views import health_check

urlpatterns = [
    path('admin/', admin.site.urls),
    path('salud/', health_check, name='health_check'),
]
