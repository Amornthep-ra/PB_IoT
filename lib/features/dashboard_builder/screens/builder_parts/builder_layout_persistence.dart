part of '../dashboard_builder_screen.dart';

extension _DashboardBuilderLayoutPersistence on _DashboardBuilderScreenState {
  bool get _hasUnsavedChanges =>
      _layoutStorage.layoutSignature(_items) != _savedLayoutSignature;

  Future<void> _loadLayoutFromStorage() async {
    try {
      final storedItems = await _layoutStorage.loadItems();
      final storedDraft = await _layoutStorage.loadBuilderDraft();

      final runtimeResolvedItems = await _runtimeValueStorage.applyToItems(
        storedItems ?? _buildInitialItems(),
      );
      final storedHistory = await _layoutStorage.loadBuilderHistory();
      await _runtimeValueStorage.pruneForItems(runtimeResolvedItems);
      final resolvedItems = _normalizeItems(runtimeResolvedItems);
      final currentSignature = _layoutStorage.layoutSignature(resolvedItems);
      final restoredHistory =
          storedHistory?.currentSignature == currentSignature
          ? storedHistory
          : null;
      final draftItems = storedDraft == null
          ? null
          : _normalizeItems(List<DashboardItem>.from(storedDraft.items));
      final hasRestorableDraft =
          storedDraft != null &&
          draftItems != null &&
          storedDraft.currentSignature != currentSignature &&
          storedDraft.currentSignature ==
              _layoutStorage.layoutSignature(draftItems);

      if (!mounted) {
        return;
      }

      _setLayoutPersistenceState(() {
        _items = resolvedItems;
        _themePreset = dashboardThemePresets.first;
        _restoreHistoryStacks(restoredHistory);
        _pendingDraftItems = hasRestorableDraft ? draftItems : null;
        _pendingDraftHistory = hasRestorableDraft
            ? (storedHistory?.currentSignature == storedDraft.currentSignature
                  ? storedHistory
                  : null)
            : null;
        _isLayoutLoading = false;
        _savedLayoutSignature = currentSignature;
        _syncItemSeedFromItems();
      });
      if (hasRestorableDraft) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_promptRestoreDraft());
        });
      } else if (storedDraft != null) {
        unawaited(_layoutStorage.clearBuilderDraft());
        unawaited(_layoutStorage.clearBuilderHistory());
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      _setLayoutPersistenceState(() {
        _isLayoutLoading = false;
        _savedLayoutSignature = _layoutStorage.layoutSignature(_items);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถโหลดเลย์เอาต์ที่บันทึกไว้ได้')),
      );
    }
  }

  Future<void> _saveLayout({bool showFeedback = true}) async {
    if (_isLayoutSaving) {
      return;
    }
    _setLayoutPersistenceState(() {
      _isLayoutSaving = true;
    });

    try {
      await _layoutStorage.saveItems(_items);
      await _draftPersistQueue.catchError((_) {});
      await _layoutStorage.clearBuilderDraft();
      if (!mounted) {
        return;
      }
      _setLayoutPersistenceState(() {
        _pendingDraftItems = null;
        _pendingDraftHistory = null;
        _savedLayoutSignature = _layoutStorage.layoutSignature(_items);
      });
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกเลย์เอาต์เรียบร้อย')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถบันทึกเลย์เอาต์ได้ในขณะนี้')),
      );
    } finally {
      if (mounted) {
        _setLayoutPersistenceState(() {
          _isLayoutSaving = false;
        });
      }
    }
  }

  Future<bool> _confirmDiscardUnsavedChanges() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final action = await showDialog<_LeaveAction>(
      context: context,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final compact = mediaQuery.size.width < 380;
        final horizontalInset = compact ? 18.0 : 24.0;
        final titleFontSize = compact ? 17.0 : 18.0;
        final bodyFontSize = compact ? 13.0 : 14.0;
        final actionHorizontalPadding = compact ? 8.0 : 12.0;
        final saveHorizontalPadding = compact ? 18.0 : 24.0;

        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: 24,
          ),
          backgroundColor: _themePreset.cardColor,
          surfaceTintColor: Colors.transparent,
          titlePadding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            compact ? 20 : 24,
            compact ? 18 : 24,
            8,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            0,
            compact ? 18 : 24,
            0,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.fromLTRB(
            compact ? 16 : 24,
            12,
            compact ? 16 : 24,
            compact ? 16 : 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: _themedBorderColor(0.78)),
          ),
          title: Text(
            'มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก',
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: _sheetHeadlineColor,
              fontWeight: FontWeight.w700,
              fontSize: titleFontSize,
              height: 1.18,
            ),
          ),
          content: Text(
            'คุณมีการเปลี่ยนแปลงวิดเจ็ตที่ยังไม่ได้บันทึก ต้องการบันทึกก่อนออกจากหน้านี้หรือไม่?',
            textAlign: TextAlign.center,
            maxLines: 3,
            style: TextStyle(
              color: _themePreset.bodyColor,
              fontSize: bodyFontSize,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: _themePreset.bodyColor,
                padding: EdgeInsets.symmetric(
                  horizontal: actionHorizontalPadding,
                  vertical: 12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => Navigator.pop(context, _LeaveAction.cancel),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC96C78),
                padding: EdgeInsets.symmetric(
                  horizontal: actionHorizontalPadding,
                  vertical: 12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => Navigator.pop(context, _LeaveAction.discard),
              child: const Text(
                'ออกโดยไม่บันทึก',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _themePreset.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: saveHorizontalPadding,
                  vertical: 12,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: () => Navigator.pop(context, _LeaveAction.save),
              child: const Text(
                'บันทึก',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    switch (action) {
      case _LeaveAction.save:
        await _saveLayout(showFeedback: false);
        return !_hasUnsavedChanges;
      case _LeaveAction.discard:
        await _draftPersistQueue.catchError((_) {});
        await _layoutStorage.clearBuilderDraft();
        await _layoutStorage.clearBuilderHistory();
        return true;
      case _LeaveAction.cancel:
      case null:
        return false;
    }
  }

  Future<void> _handlePopInvoked(bool didPop) async {
    if (didPop) {
      return;
    }
    final shouldLeave = await _confirmDiscardUnsavedChanges();
    if (!mounted || !shouldLeave) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _promptRestoreDraft() async {
    final draftItems = _pendingDraftItems;
    if (!mounted || draftItems == null || _isLayoutLoading) {
      return;
    }

    final restoreDraft = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _themePreset.cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: _themedBorderColor(0.78)),
          ),
          title: Text(
            'Restore draft?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _sheetHeadlineColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'An autosaved dashboard draft was found. Restore it or discard the draft and keep the saved layout.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _themePreset.bodyColor, height: 1.35),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Discard',
                style: TextStyle(color: Color(0xFFC96C78)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: _themePreset.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Restore',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (restoreDraft == true) {
      _setLayoutPersistenceState(() {
        _items = _normalizeItems(draftItems);
        _restoreHistoryStacks(_pendingDraftHistory);
        _pendingDraftItems = null;
        _pendingDraftHistory = null;
        _syncItemSeedFromItems();
      });
      _queuePersistBuilderDraft();
      _queuePersistBuilderHistory();
      return;
    }

    _setLayoutPersistenceState(() {
      _pendingDraftItems = null;
      _pendingDraftHistory = null;
    });
    await _layoutStorage.clearBuilderDraft();
    await _layoutStorage.clearBuilderHistory();
  }

  void _syncItemSeedFromItems() {
    var maxSeed = _itemSeed;
    final suffixPattern = RegExp(r'-(\d+)$');
    for (final item in _items) {
      final match = suffixPattern.firstMatch(item.id);
      if (match == null) {
        continue;
      }
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null && parsed > maxSeed) {
        maxSeed = parsed;
      }
    }
    _itemSeed = maxSeed;
  }
}
