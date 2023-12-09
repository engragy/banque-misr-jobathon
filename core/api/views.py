from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView


class LiveAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request, format=None):
        from django.conf import settings
        from django.db import connections
        from django.db.utils import OperationalError

        db_conn = connections['default']
        try:
            c = db_conn.cursor()
        except OperationalError:
            connected = False
            return Response(f'Maintenance ... no connection to database {settings.DATABASES["default"]}')
        else:
            connected = True
            return Response('Well Done')
