-- Storage policies for proofs bucket
CREATE POLICY "Users can upload proof images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'proofs' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Authenticated users can read proof images"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'proofs' AND
    auth.role() = 'authenticated'
  );

CREATE POLICY "Users can delete own proof images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'proofs' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
