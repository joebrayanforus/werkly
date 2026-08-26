delete from public.jobs
where external_id in (
  'demo-celonis-data',
  'demo-personio-ai',
  'demo-siemens-flutter',
  'demo-allianz-bi',
  'demo-flix-ux'
);
