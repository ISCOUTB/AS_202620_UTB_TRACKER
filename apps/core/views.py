from django.http import JsonResponse


def health_check(request):
    """
    Endpoint minimo para confirmar que el esqueleto arranca correctamente.
    No es logica de negocio: es fontaneria para la semana 4.
    """
    return JsonResponse({"status": "ok", "proyecto": "Tractar"})
