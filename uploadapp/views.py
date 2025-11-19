from django.shortcuts import render, redirect

# Create your views here.
from django.core.files.storage import FileSystemStorage
from .models import UploadFile

import logging

logger = logging.getLogger('uploadapp')

def upload_list(request):
    files = UploadFile.objects.all().order_by('-uploaded_at')
    logger.info('upload_list 요청 처리')
    return render(request, 'uploadapp/upload_list.html', {'files': files})

def upload_file(request):
    if request.method == 'POST' and request.FILES.get('file'):
        f = request.FILES['file']
        fs = FileSystemStorage()
        filename = fs.save(f.name, f)
        UploadFile.objects.create(file=filename)
        logger.info(f'upload_file 처리 [{filename} 업로드 됨]')
        return redirect('upload_list')
    logger.info('upload_form 요청 처리')
    return render(request, 'uploadapp/upload_form.html')
