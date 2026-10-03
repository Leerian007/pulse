import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/hairline_divider.dart';
import '../../../../core/widgets/pressable.dart';
import '../../domain/entities/user_profile.dart';

/// 个人主页头部卡片。
///
/// 排版是**居中对称**的：头像 → 昵称 → handle → 简介 → 数据 → 元信息。
/// 居中对齐比左对齐更"安静"，也与"大量留白"的极简基调一致。
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    this.onEditBio,
  });

  final UserProfile profile;

  final VoidCallback? onEditBio;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadius.cardAll,
        boxShadow: AppShadows.cardFor(palette.brightness),
      ),
      child: Column(
        children: <Widget>[
          AppAvatar(
            seed: profile.id,
            emoji: profile.emoji,
            size: 84,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 昵称 + 认证标记
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title2.copyWith(color: palette.label),
                ),
              ),
              if (profile.isVerified) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 18,
                  color: palette.accent,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '@${profile.handle}',
            style: AppTypography.subheadline.copyWith(
              color: palette.labelSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: AppTypography.callout.copyWith(color: palette.label),
          ),

          if (onEditBio != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Pressable(
              onTap: onEditBio,
              scale: 0.94,
              borderRadius: AppRadius.pillAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: palette.fill,
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  '编辑简介',
                  style: AppTypography.subheadline.copyWith(
                    color: palette.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // 数据行
          Row(
            children: <Widget>[
              Expanded(
                child: _Stat(
                  value: formatCount(profile.postCount),
                  label: '动态',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _Stat(
                  value: formatCount(profile.followingCount),
                  label: '关注',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _Stat(
                  value: formatCount(profile.followerCount),
                  label: '粉丝',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const HairlineDivider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            '获赞 ${formatCount(profile.likesReceived)}'
            '${profile.location == null ? '' : ' · ${profile.location}'}'
            ' · ${formatJoinDate(profile.joinedAt)}',
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(
              color: palette.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个数据项：数字用 title3 + 等宽数字，标签用 caption1 灰字。
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Column(
      children: <Widget>[
        Text(
          value,
          style: AppTypography.title3.copyWith(
            color: palette.label,
            // 用等宽数字，三个数字块切换时不会横向抖动。
            fontFeatures: AppTypography.tabularNumber.fontFeatures,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.caption1.copyWith(
            color: palette.labelSecondary,
          ),
        ),
      ],
    );
  }
}

/// 数据项之间的竖向 hairline。
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 28,
      child: HairlineDivider(axis: Axis.vertical),
    );
  }
}
