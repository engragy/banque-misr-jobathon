from django.urls import path

from core.api.views import LiveAPIView

urlpatterns = [
    path("live/", LiveAPIView.as_view(), name="is-alive"),
]
