rm submission.zip
Get-ChildItem ./* -Exclude 'cp4_processor*', 'Test Files' | Compress-Archive -DestinationPath submission.zip -Update