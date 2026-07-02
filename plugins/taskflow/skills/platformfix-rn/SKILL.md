---
name: platformfix-rn
description: React Native iOS/Android platform-fix handbook — exact code patterns for keyboard avoidance, modal stacking, shadows/elevation, safe area, back button, status bar, and build artifact cleanup, with a quick decision table.
---

# Platform Fix Guide – React Native (iOS & Android)

Use this skill when:
- A bug appears on only one platform
- Implementing keyboard, modal, shadow, safe area, back button, or status bar behavior
- A UI layout looks correct on one platform but broken on the other
- Building any screen that uses scrollable content + inputs

---

## Step 1: Diagnose

Confirm which platform(s) show the issue:
```bash
# Run on Android device/emulator
npx react-native run-android

# Run on iOS simulator
npx react-native run-ios

# Clear Metro cache if behavior is inconsistent between runs
npx react-native start --reset-cache
```

Then check the Quick Decision Table at the bottom of this guide for a fast match.

---

## iOS-Specific Issues & Fixes

### Keyboard Avoiding View
**Symptom:** Input fields hidden behind the keyboard on iOS.
```tsx
// CORRECT: behavior="padding" on iOS, undefined on Android
// Bottom action bar goes OUTSIDE the KAV — it must never lift with the keyboard
<KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : undefined}
  style={{ flex: 1 }}
>
  <ScrollView contentContainerStyle={{ paddingBottom: scale(80) }}>
    {/* all form fields */}
  </ScrollView>
</KeyboardAvoidingView>
<View style={styles.actionBar}>
  {/* submit button — outside KAV */}
</View>
```

### Modal Stacking
**Symptom:** A second (inner) modal triggered from inside a first (outer) modal fails to open on iOS — no error, just nothing happens.
```tsx
// WRONG: Sibling modals — inner modal fails silently on iOS
<Modal visible={outerVisible}>...</Modal>
<Modal visible={innerVisible}>...</Modal>

// CORRECT: Inner modal nested inside the outer modal's JSX tree
<Modal visible={outerVisible}>
  <View>
    {/* outer content */}
    <Modal visible={innerVisible}>
      {/* inner content */}
    </Modal>
  </View>
</Modal>
```
Rule from CLAUDE.md: React Native `Modal`-on-`Modal` on iOS requires inner modals inside the outer modal's JSX tree so iOS presents them from the correct UIViewController.

### react-native-paper TextInput inside ScrollView
**Symptom:** Keyboard avoidance conflicts; text cursor invisible; scroll fights input scroll.

`LongTextInputCustom` (Paper TextInput + TouchableWithoutFeedback) must NOT be used inside a `ScrollView` on iOS.
```tsx
// WRONG: LongTextInputCustom inside ScrollView on iOS
<ScrollView>
  <LongTextInputCustom ... />
</ScrollView>

// CORRECT: Direct Paper TextInput
import { TextInput } from 'react-native-paper'
<TextInput
  multiline
  scrollEnabled={false}          // prevents inner scroll conflicting with parent ScrollView
  selectionColor={COLORS.primary} // iOS cursor/selection highlight color
  cursorColor={COLORS.primary}    // Android cursor color
  ...
/>
```

### Shadow Styles
iOS uses `shadow*` props; Android uses `elevation`.
```tsx
const styles = StyleSheet.create({
  card: {
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
      },
      android: { elevation: 4 },
    }),
  },
})
```

### Safe Area (Notch / Dynamic Island / Home Indicator)
```tsx
import { useSafeAreaInsets } from 'react-native-safe-area-context'

// In component:
const insets = useSafeAreaInsets()
// insets.top  → space below status bar / notch
// insets.bottom → space above home indicator
<View style={{ paddingTop: insets.top, paddingBottom: insets.bottom }}>
```
Or use `SafeAreaView` from `react-native-safe-area-context` with `edges` prop:
```tsx
import { SafeAreaView } from 'react-native-safe-area-context'
<SafeAreaView edges={['top', 'bottom']} style={{ flex: 1 }}>
```

### Status Bar (iOS)
```tsx
import { StatusBar } from 'react-native'
// barStyle controls text/icon color: "dark-content" or "light-content"
<StatusBar barStyle="dark-content" backgroundColor="transparent" translucent />
```

### Back Navigation Gesture
iOS users expect swipe-from-left to go back. Only disable when you have a confirmed reason:
```tsx
navigation.setOptions({ gestureEnabled: false })
```

### Date / Time Picker
iOS renders inline spinner; Android shows a dialog. Use `@react-native-community/datetimepicker` and wrap with `Platform.OS`:
```tsx
{Platform.OS === 'ios' ? (
  <DateTimePicker display="spinner" ... />
) : (
  showPicker && <DateTimePicker display="default" ... />
)}
```

---

## Android-Specific Issues & Fixes

### Keyboard Avoiding View
Android handles keyboard avoidance at the OS level. Do NOT set `behavior` on Android.
In `android/app/src/main/AndroidManifest.xml`:
```xml
<activity android:windowSoftInputMode="adjustResize" ...>
```
In React:
```tsx
<KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
```

### Hardware Back Button
```tsx
import { BackHandler } from 'react-native'
import { useFocusEffect } from '@react-navigation/native'

useFocusEffect(
  useCallback(() => {
    const handler = BackHandler.addEventListener('hardwareBackPress', () => {
      // return true  → consume event (prevent default back action)
      // return false → let default back action proceed
      return false
    })
    return () => handler.remove()  // cleanup on blur
  }, [])
)
```

### Status Bar Color
```tsx
<StatusBar backgroundColor={COLORS.primary} barStyle="light-content" />
```

### Ripple Effect on Touchables
```tsx
// Option A: Pressable with android_ripple
<Pressable android_ripple={{ color: COLORS.lightBlue, borderless: false }}>
  {/* content */}
</Pressable>

// Option B: TouchableNativeFeedback
<TouchableNativeFeedback
  background={TouchableNativeFeedback.Ripple(COLORS.lightBlue, false)}
>
  <View>{/* content — must be a View, not a custom component */}</View>
</TouchableNativeFeedback>
```

### Font Scaling
Android respects system font size. This can break fixed-height layouts that use `scale()`.
```tsx
// On any Text component with a fixed container height:
<Text allowFontScaling={false} style={styles.label}>...</Text>
```

### Runtime Permissions
```tsx
import { PermissionsAndroid, Platform } from 'react-native'

if (Platform.OS === 'android') {
  const granted = await PermissionsAndroid.request(
    PermissionsAndroid.PERMISSIONS.CAMERA,
    { title: 'Camera Permission', message: 'Needed to scan QR codes', buttonPositive: 'Allow' }
  )
  if (granted !== PermissionsAndroid.RESULTS.GRANTED) {
    showSnackbar('Camera permission denied', true)
    return
  }
}
```

### Gradle Build Failures
```bash
# Clean Gradle cache
cd android && ./gradlew clean && cd ..

# Full clean rebuild
cd android && ./gradlew clean && cd .. && npx react-native run-android
```

---

## Cross-Platform Patterns

### Platform.select()
```tsx
const hitSlop = Platform.select({
  ios:     { top: 10, bottom: 10, left: 10, right: 10 },
  android: { top: 8,  bottom: 8,  left: 8,  right: 8  },
  default: { top: 8,  bottom: 8,  left: 8,  right: 8  },
})
```

### FlatList Performance (Both Platforms)
```tsx
<FlatList
  removeClippedSubviews={true}
  maxToRenderPerBatch={10}
  windowSize={10}
  initialNumToRender={8}
  getItemLayout={(_, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
  keyExtractor={(item) => item.id.toString()}
  renderItem={({ item }) => <MemoizedItem item={item} />}  // always React.memo
/>
```

### Scaling Reminder
From `app/utils/scalingUtils.tsx` — always use these, never raw px values:
```tsx
import { scale, verticalScale } from 'app/utils/scalingUtils'
// scale()         → horizontal dimensions and font sizes
// verticalScale() → heights, vertical paddings, margins
```

---

## Build Artifact Cleanup

When Metro bundler behavior is inconsistent, run in order:

```bash
# 1. Reset Metro cache
npx react-native start --reset-cache

# 2. Clear watchman (macOS/Linux)
watchman watch-del-all

# 3. iOS: clean Xcode build + reinstall Pods
cd ios && xcodebuild clean && rm -rf build && pod install && cd ..

# 4. Android: clean Gradle
cd android && ./gradlew clean && cd ..

# 5. Clear node_modules (last resort — takes longest)
rm -rf node_modules && npm install
```

---

## Quick Decision Table

| Symptom | Platform | Fix |
|---------|----------|-----|
| Input hidden behind keyboard | iOS | KAV `behavior="padding"` + action bar outside KAV |
| Input hidden behind keyboard | Android | `windowSoftInputMode="adjustResize"` in manifest |
| Second modal doesn't open | iOS | Nest inner modal inside outer modal JSX tree |
| No shadow visible | Android | Use `elevation` instead of `shadow*` props |
| Text jumps size / layout breaks | Android | `allowFontScaling={false}` on fixed-height text |
| Back button does nothing | Android | Add `BackHandler` listener via `useFocusEffect` |
| Ripple effect missing | Android | Use `Pressable android_ripple` or `TouchableNativeFeedback` |
| Status bar overlaps content | Both | Use `useSafeAreaInsets()` or `SafeAreaView` with `edges` |
| Paper TextInput + ScrollView broken | iOS | Replace with direct Paper TextInput, `scrollEnabled={false}` |
| Cursor not visible in TextInput | iOS | Add `selectionColor={COLORS.primary}` |
| Build cache stale / hot reload broken | Both | Reset Metro; clean Gradle (Android) or Xcode (iOS) |
| Swipe back gesture interfering | iOS | `navigation.setOptions({ gestureEnabled: false })` |
| Date picker wrong UI | Both | Check `Platform.OS` and use appropriate `display` mode |
