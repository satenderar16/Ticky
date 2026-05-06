import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/contest_model.dart';

final currentContestProvider = StateProvider<CurrentContestState>(
  (ref) => const CurrentContestState(),
);

class CurrentContestState {
  final ContestDetailModel? contest;
  final ContestSource? source;

  const CurrentContestState({this.contest, this.source});

  CurrentContestState copyWith({
    ContestDetailModel? contest,
    ContestSource? source,
  }) {
    return CurrentContestState(
      contest: contest ?? this.contest,
      source: source ?? this.source,
    );
  }
}

enum ContestSource { participates, live }

// Logo Footer for infinite list:

class AppBottomLogoTile extends StatelessWidget {
  const AppBottomLogoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = TextTheme.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: 40,
        bottom: MediaQuery.paddingOf(context).bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            // crossAxisAlignment: CrossAxisAlignment.cente,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(height: 35, './assets/logo.png'),
              ),
              Text(
                'Tikcy',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.outlineVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          Text(
            'v0.1.0',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.outlineVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
