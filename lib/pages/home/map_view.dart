part of '../home_page.dart';

class _MapView extends StatelessWidget {
  const _MapView({
    required this.jobs,
    required this.distance,
    required this.center,
    required this.savedJobs,
    required this.onDistanceChanged,
    required this.onDistanceChangeEnd,
    required this.onOpenJob,
    required this.onToggleSaved,
  });

  final List<Job> jobs;
  final int distance;
  final LatLng center;
  final Set<int> savedJobs;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<double> onDistanceChangeEnd;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<int> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final nearbyJobs = jobs
        .where(
          (job) =>
              _distanceBetweenKm(
                center.latitude,
                center.longitude,
                job.latitude,
                job.longitude,
              ) <=
              distance,
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Padding(
          padding: EdgeInsets.all(wide ? 24 : 14),
          child: wide
              ? Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: _BigMap(
                        jobs: nearbyJobs,
                        distance: distance,
                        center: center,
                        onDistanceChanged: onDistanceChanged,
                        onDistanceChangeEnd: onDistanceChangeEnd,
                        onOpenJob: onOpenJob,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 4,
                      child: _MapJobList(
                        jobs: nearbyJobs,
                        savedJobs: savedJobs,
                        onOpenJob: onOpenJob,
                        onToggleSaved: onToggleSaved,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _BigMap(
                        jobs: nearbyJobs,
                        distance: distance,
                        center: center,
                        onDistanceChanged: onDistanceChanged,
                        onDistanceChangeEnd: onDistanceChangeEnd,
                        onOpenJob: onOpenJob,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 4,
                      child: _MapJobList(
                        jobs: nearbyJobs,
                        savedJobs: savedJobs,
                        onOpenJob: onOpenJob,
                        onToggleSaved: onToggleSaved,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _BigMap extends StatelessWidget {
  const _BigMap({
    required this.jobs,
    required this.distance,
    required this.center,
    required this.onDistanceChanged,
    required this.onDistanceChangeEnd,
    required this.onOpenJob,
  });
  final List<Job> jobs;
  final int distance;
  final LatLng center;
  final ValueChanged<double> onDistanceChanged;
  final ValueChanged<double> onDistanceChangeEnd;
  final ValueChanged<Job> onOpenJob;

  @override
  Widget build(BuildContext context) {
    final markers = jobs
        .map(
          (job) => Marker(
            key: ValueKey('job-${job.id}'),
            point: LatLng(job.latitude, job.longitude),
            width: 52,
            height: 52,
            child: Tooltip(
              message:
                  '${job.title}\n${job.company} · ${job.compatibility.scored ? '${job.match}% ${context.tr('compatibility')}' : context.tr('profileNeedsCompletion')}',
              child: Semantics(
                button: true,
                label: context.trFormat('openJobAt', {
                  'job': job.title,
                  'company': job.company,
                }),
                child: InkWell(
                  onTap: () => onOpenJob(job),
                  customBorder: const CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.work_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 11.3,
                minZoom: 4,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'de.werkly.app',
                  maxZoom: 19,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: center,
                      radius: distance * 1000,
                      useRadiusInMeter: true,
                      color: _green.withValues(alpha: .08),
                      borderColor: _green.withValues(alpha: .55),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
                RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              width: 245,
              padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x18000000), blurRadius: 15),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_bike_rounded,
                        color: _green,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        context.tr('maximumDistance'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$distance km',
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: distance.clamp(5, 100).toDouble(),
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: onDistanceChanged,
                    onChangeEnd: onDistanceChangeEnd,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapJobList extends StatelessWidget {
  const _MapJobList({
    required this.jobs,
    required this.savedJobs,
    required this.onOpenJob,
    required this.onToggleSaved,
  });
  final List<Job> jobs;
  final Set<int> savedJobs;
  final ValueChanged<Job> onOpenJob;
  final ValueChanged<int> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.trFormat('nearbyJobs', {'count': jobs.length}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            const Icon(Icons.sort_rounded, color: _muted),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => SizedBox(
              height: 230,
              child: _JobCard(
                job: jobs[index],
                compact: true,
                saved: savedJobs.contains(jobs[index].id),
                onTap: () => onOpenJob(jobs[index]),
                onSave: () => onToggleSaved(jobs[index].id),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

