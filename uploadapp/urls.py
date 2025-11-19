from django.urls import path
from . import views

urlpatterns = [
    path('', views.upload_list, name='upload_list'),
    path('new/', views.upload_file, name='upload_file'),
]
