import 'models.dart';

/// Built-in exercise library. IDs are stable and referenced by plans and
/// logs. Names, steps, and tips are seed data, kept out of the ARB files.
const List<Exercise> exerciseLibrary = [
  // ----- Chest -----
  Exercise(
    id: 'benchPress',
    name: 'Barbell Bench Press',
    group: 'chest',
    equipment: 'barbell',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'triceps'],
    isCompound: true,
    steps: [
      'Lie on the bench with your eyes under the bar and your feet flat on the floor.',
      'Hold the bar a little wider than your shoulders and lift it off the rack, over your chest.',
      'Lower the bar slowly to the middle of your chest. Keep your elbows about 45 degrees from your body.',
      'Push the bar back up until your arms are straight.',
    ],
    tips: [
      'Pull your shoulder blades together and keep them on the bench.',
      'Touch your chest lightly. Never bounce the bar.',
      'When the weight is heavy, ask for a helper or use the safety bars.',
    ],
  ),
  Exercise(
    id: 'inclineBenchPress',
    name: 'Incline Barbell Press',
    group: 'chest',
    equipment: 'barbell',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'triceps'],
    isCompound: true,
    steps: [
      'Set the bench to an angle of 30 to 45 degrees.',
      'Hold the bar a little wider than your shoulders and lift it off the rack.',
      'Lower the bar slowly to your upper chest.',
      'Push back up until your arms are straight.',
    ],
    tips: [
      'A higher angle works the shoulders more, so stay near 30 degrees.',
      'Keep your hips on the bench for the whole set.',
    ],
  ),
  Exercise(
    id: 'dbBenchPress',
    name: 'Dumbbell Bench Press',
    group: 'chest',
    equipment: 'dumbbell',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'triceps'],
    isCompound: true,
    steps: [
      'Sit on the bench with a dumbbell on each thigh. Lie back and lift them to your chest.',
      'Start with the dumbbells over your chest, palms facing forward.',
      'Lower them down and out until your elbows drop below the bench.',
      'Push back up and bring the dumbbells slightly together at the top.',
    ],
    tips: [
      'Dumbbells give a deeper stretch than the bar. Control them the whole way.',
      'Do not let the dumbbells move toward your face.',
    ],
  ),
  Exercise(
    id: 'inclineDbPress',
    name: 'Incline Dumbbell Press',
    group: 'chest',
    equipment: 'dumbbell',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'triceps'],
    isCompound: true,
    steps: [
      'Set the bench to a 30 degree angle and sit with the dumbbells on your thighs.',
      'Lie back and press the dumbbells over your upper chest.',
      'Lower them slowly until you feel a stretch across your chest.',
      'Push back up. Do not lock your elbows hard.',
    ],
    tips: [
      'Keep your wrists straight, above your elbows.',
      'Lower slowly, counting to two, on every rep.',
    ],
  ),
  Exercise(
    id: 'chestFly',
    name: 'Cable Chest Fly',
    group: 'chest',
    equipment: 'cable',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders'],
    steps: [
      'Set both pulleys at chest height and hold a handle in each hand.',
      'Step forward, one foot in front of the other, with a small bend in your elbows.',
      'Bring your hands together in a wide curve in front of your chest.',
      'Return slowly until you feel a stretch in your chest.',
    ],
    tips: [
      'Keep the same small elbow bend the whole time. Think of a hug, not a press.',
      'Squeeze your chest for one second when your hands meet.',
    ],
  ),
  Exercise(
    id: 'pecDeck',
    name: 'Pec Deck Machine',
    group: 'chest',
    equipment: 'machine',
    primaryMuscles: ['chest'],
    steps: [
      'Set the seat so the handles are at chest height.',
      'Sit up straight with your back flat against the pad.',
      'Bring the handles together in front of you.',
      'Open back up slowly until you feel a comfortable stretch.',
    ],
    tips: [
      'Do not let the weights bang down between reps.',
      'A good last exercise after your pressing work.',
    ],
  ),
  Exercise(
    id: 'pushUp',
    name: 'Push-Up',
    group: 'chest',
    equipment: 'bodyweight',
    primaryMuscles: ['chest'],
    secondaryMuscles: ['shoulders', 'triceps', 'abs'],
    isCompound: true,
    steps: [
      'Put your hands on the floor, a little wider than your shoulders.',
      'Make a straight line from your head to your heels.',
      'Lower your chest until it is just above the floor.',
      'Push back up until your arms are straight.',
    ],
    tips: [
      'Squeeze your glutes and abs so your hips do not drop.',
      'Too easy? Put your feet up higher, or stop for a moment at the bottom.',
    ],
  ),
  Exercise(
    id: 'chestDip',
    name: 'Chest Dip',
    group: 'chest',
    equipment: 'bodyweight',
    primaryMuscles: ['chest', 'triceps'],
    secondaryMuscles: ['shoulders'],
    isCompound: true,
    steps: [
      'Hold the parallel bars and push up until your arms are straight.',
      'Lean your upper body slightly forward.',
      'Lower down until your upper arms are about level with the floor.',
      'Push back up. Do not lock your arms hard.',
    ],
    tips: [
      'Leaning forward works the chest more than the triceps.',
      'Stop going down if you feel pain in the front of your shoulder.',
    ],
  ),

  // ----- Back -----
  Exercise(
    id: 'deadlift',
    name: 'Deadlift',
    group: 'back',
    equipment: 'barbell',
    primaryMuscles: ['lowerBack', 'glutes', 'hamstrings'],
    secondaryMuscles: ['lats', 'traps', 'forearms', 'quads'],
    isCompound: true,
    steps: [
      'Stand with the bar over the middle of your feet, feet about hip width apart.',
      'Bend down from your hips and hold the bar just outside your legs.',
      'Tighten your stomach, flatten your back, and lift your chest.',
      'Push through your legs and stand up tall. Keep the bar close to your body.',
      'Push your hips back and lower the bar slowly.',
    ],
    tips: [
      'The bar should touch your legs all the way up and down.',
      'Never let your lower back round. Tighten your stomach again before every rep.',
      'Good form matters most here. Film yourself, or ask someone to check you.',
    ],
  ),
  Exercise(
    id: 'pullUp',
    name: 'Pull-Up',
    group: 'back',
    equipment: 'bodyweight',
    primaryMuscles: ['lats'],
    secondaryMuscles: ['biceps', 'upperBack', 'forearms'],
    isCompound: true,
    steps: [
      'Hang from the bar with your palms facing away, hands a little wider than your shoulders.',
      'Pull your shoulder blades down, then pull your chin over the bar.',
      'Lower yourself all the way down until your arms are straight.',
    ],
    tips: [
      'Think about pulling your elbows down to your hips.',
      'Use the assisted machine or a band if you cannot do 5 good reps yet.',
    ],
  ),
  Exercise(
    id: 'chinUp',
    name: 'Chin-Up',
    group: 'back',
    equipment: 'bodyweight',
    primaryMuscles: ['lats', 'biceps'],
    secondaryMuscles: ['upperBack', 'forearms'],
    isCompound: true,
    steps: [
      'Hang from the bar with your palms facing you, hands about shoulder width apart.',
      'Pull your chin over the bar and lead with your chest.',
      'Lower down slowly until your arms are straight.',
    ],
    tips: [
      'Your palms facing you use the biceps more, so you will be a little stronger than on pull-ups.',
      'Do not swing. Keep your stomach tight.',
    ],
  ),
  Exercise(
    id: 'latPulldown',
    name: 'Lat Pulldown',
    group: 'back',
    equipment: 'cable',
    primaryMuscles: ['lats'],
    secondaryMuscles: ['biceps', 'upperBack'],
    isCompound: true,
    steps: [
      'Sit down and put your thighs under the pads.',
      'Hold the bar wider than your shoulders.',
      'Pull the bar down to your upper chest as you lean back a little.',
      'Let the bar rise slowly until your arms are straight.',
    ],
    tips: [
      'Pull with your elbows, not your hands.',
      'Do not pull the bar behind your neck.',
    ],
  ),
  Exercise(
    id: 'barbellRow',
    name: 'Barbell Row',
    group: 'back',
    equipment: 'barbell',
    primaryMuscles: ['upperBack', 'lats'],
    secondaryMuscles: ['biceps', 'lowerBack', 'forearms'],
    isCompound: true,
    steps: [
      'Bend forward from your hips to about 45 degrees, knees slightly bent.',
      'Hold the bar about shoulder width, arms hanging straight down.',
      'Pull the bar up to your lower ribs.',
      'Lower it slowly. Do not drop your chest.',
    ],
    tips: [
      'Keep your back flat and tight, like in the deadlift.',
      'If you must swing your hips to lift it, the bar is too heavy.',
    ],
  ),
  Exercise(
    id: 'dbRow',
    name: 'One-Arm Dumbbell Row',
    group: 'back',
    equipment: 'dumbbell',
    primaryMuscles: ['lats', 'upperBack'],
    secondaryMuscles: ['biceps', 'forearms'],
    isCompound: true,
    steps: [
      'Put one knee and the same-side hand on a bench.',
      'Hold the dumbbell in your other hand, arm hanging straight down.',
      'Pull the dumbbell up to your hip. Keep your body still.',
      'Lower it to a full stretch. Do the reps, then switch sides.',
    ],
    tips: [
      'Pull to your hip, not your shoulder, to keep the back working.',
      'Do not turn your body to lift more weight.',
    ],
  ),
  Exercise(
    id: 'seatedRow',
    name: 'Seated Cable Row',
    group: 'back',
    equipment: 'cable',
    primaryMuscles: ['upperBack', 'lats'],
    secondaryMuscles: ['biceps'],
    isCompound: true,
    steps: [
      'Sit with your feet on the platform and your knees slightly bent.',
      'Hold the handle with your palms facing each other and sit up straight.',
      'Pull the handle to your stomach and squeeze your shoulder blades together.',
      'Let your arms reach forward fully. Do not round your back.',
    ],
    tips: [
      'Keep your chest up for the whole set.',
      'Pause for one second at your stomach on every rep.',
    ],
  ),
  Exercise(
    id: 'tBarRow',
    name: 'T-Bar Row',
    group: 'back',
    equipment: 'barbell',
    primaryMuscles: ['upperBack', 'lats'],
    secondaryMuscles: ['biceps', 'lowerBack'],
    isCompound: true,
    steps: [
      'Stand over the bar and hold the handles with a flat back.',
      'Keep your upper body at about 45 degrees.',
      'Pull the weight up to your chest.',
      'Lower it slowly to a full stretch.',
    ],
    tips: [
      'Smaller plates let you move through a longer range.',
      'Do not stand up as you get tired. Keep bending forward from your hips.',
    ],
  ),
  Exercise(
    id: 'straightArmPulldown',
    name: 'Straight-Arm Pulldown',
    group: 'back',
    equipment: 'cable',
    primaryMuscles: ['lats'],
    secondaryMuscles: ['triceps', 'abs'],
    steps: [
      'Stand facing a high pulley and hold the bar with straight arms.',
      'Bend forward a little and keep your stomach tight.',
      'Pull the bar down to your thighs in a curve.',
      'Return slowly until your arms are above your head.',
    ],
    tips: [
      'Keep your arms almost straight. The movement comes from your shoulders.',
      'Feel the stretch in your back at the top of every rep.',
    ],
  ),
  Exercise(
    id: 'backExtension',
    name: 'Back Extension',
    group: 'back',
    equipment: 'bodyweight',
    primaryMuscles: ['lowerBack', 'glutes'],
    secondaryMuscles: ['hamstrings'],
    steps: [
      'Set the pad just below your hips and hook your feet in.',
      'Cross your arms over your chest.',
      'Lower your upper body until you feel a stretch in the back of your legs.',
      'Raise back up until your body is in a straight line.',
    ],
    tips: [
      'Do not bend backward past a straight line at the top.',
      'Hold a weight plate against your chest to make it harder.',
    ],
  ),
  Exercise(
    id: 'shrug',
    name: 'Dumbbell Shrug',
    group: 'back',
    equipment: 'dumbbell',
    primaryMuscles: ['traps'],
    secondaryMuscles: ['forearms'],
    steps: [
      'Stand up straight with a heavy dumbbell in each hand.',
      'Lift your shoulders straight up toward your ears.',
      'Hold at the top for one second, then lower slowly.',
    ],
    tips: [
      'Move straight up and down. Do not roll your shoulders.',
      'Keep your arms relaxed. Your traps do the work.',
    ],
  ),

  // ----- Shoulders -----
  Exercise(
    id: 'overheadPress',
    name: 'Overhead Press',
    group: 'shoulders',
    equipment: 'barbell',
    primaryMuscles: ['shoulders'],
    secondaryMuscles: ['triceps', 'traps', 'abs'],
    isCompound: true,
    steps: [
      'Hold the bar at shoulder height, hands just outside your shoulders.',
      'Tighten your stomach and squeeze your glutes.',
      'Push the bar straight up above your head. Move your head back a little as it passes.',
      'Finish with the bar over the middle of your feet, then lower it to your shoulders.',
    ],
    tips: [
      'Do not lean back to force reps. That changes the exercise.',
      'Keep your wrists straight and your elbows under the bar.',
    ],
  ),
  Exercise(
    id: 'dbShoulderPress',
    name: 'Seated Dumbbell Press',
    group: 'shoulders',
    equipment: 'dumbbell',
    primaryMuscles: ['shoulders'],
    secondaryMuscles: ['triceps', 'traps'],
    isCompound: true,
    steps: [
      'Sit on an upright bench with a dumbbell at each shoulder.',
      'Push both dumbbells up above your head until your arms are straight.',
      'Lower them slowly back to shoulder height.',
    ],
    tips: [
      'Keep your lower back on the pad. Do not arch it much.',
      'Lower until your elbows reach about 90 degrees.',
    ],
  ),
  Exercise(
    id: 'arnoldPress',
    name: 'Arnold Press',
    group: 'shoulders',
    equipment: 'dumbbell',
    primaryMuscles: ['shoulders'],
    secondaryMuscles: ['triceps'],
    steps: [
      'Sit and hold the dumbbells at shoulder height, palms facing you.',
      'Push up while turning your palms to face forward.',
      'Turn your palms back as you lower down.',
    ],
    tips: [
      'Use a lighter weight than a normal press. The turning is the point.',
      'Move smoothly. Do not jerk through the turn.',
    ],
  ),
  Exercise(
    id: 'lateralRaise',
    name: 'Dumbbell Lateral Raise',
    group: 'shoulders',
    equipment: 'dumbbell',
    primaryMuscles: ['shoulders'],
    steps: [
      'Stand up straight with a light dumbbell in each hand at your sides.',
      'Lift both arms out to the sides until they reach shoulder height.',
      'Lower them slowly back to your sides.',
    ],
    tips: [
      'Lead with your elbows, little fingers slightly up, like pouring water.',
      'If you must swing, the weight is too heavy. Use less.',
    ],
  ),
  Exercise(
    id: 'frontRaise',
    name: 'Dumbbell Front Raise',
    group: 'shoulders',
    equipment: 'dumbbell',
    primaryMuscles: ['shoulders'],
    steps: [
      'Hold a dumbbell in each hand in front of your thighs.',
      'Lift one arm straight in front of you to shoulder height.',
      'Lower it slowly, then switch arms.',
    ],
    tips: [
      'Keep a small bend in your elbow and do not rock your body.',
      'Skip this on heavy pressing days. Your front shoulders are already tired.',
    ],
  ),
  Exercise(
    id: 'rearDeltFly',
    name: 'Rear Delt Fly',
    group: 'shoulders',
    equipment: 'dumbbell',
    primaryMuscles: ['shoulders', 'upperBack'],
    steps: [
      'Bend forward until your upper body is almost level with the floor.',
      'Let the dumbbells hang under your chest, palms facing each other.',
      'Lift both arms out to the sides and squeeze your shoulder blades together.',
      'Lower them slowly. Do not stand up.',
    ],
    tips: [
      'Use a very light weight and very clean form.',
      'Think about pulling your hands apart, not lifting them up.',
    ],
  ),
  Exercise(
    id: 'facePull',
    name: 'Cable Face Pull',
    group: 'shoulders',
    equipment: 'cable',
    primaryMuscles: ['shoulders', 'upperBack'],
    secondaryMuscles: ['traps'],
    steps: [
      'Set a rope handle at upper chest height.',
      'Hold the ends of the rope with your thumbs pointing back.',
      'Pull the rope toward your face and split the ends past your ears.',
      'Return slowly with your shoulders down.',
    ],
    tips: [
      'Finish each rep with your elbows high and your hands beside your head.',
      'Great for healthy shoulders. Do these on every pull day.',
    ],
  ),
  Exercise(
    id: 'uprightRow',
    name: 'Cable Upright Row',
    group: 'shoulders',
    equipment: 'cable',
    primaryMuscles: ['shoulders', 'traps'],
    secondaryMuscles: ['biceps'],
    steps: [
      'Stand and hold a straight bar on a low pulley, hands about shoulder width apart.',
      'Pull the bar up close to your body to chest height, leading with your elbows.',
      'Lower it slowly.',
    ],
    tips: [
      'Stop at chest height. Pulling higher can hurt the shoulder.',
      'A wider grip is easier on the wrists and shoulders.',
    ],
  ),

  // ----- Arms -----
  Exercise(
    id: 'bicepCurl',
    name: 'Dumbbell Bicep Curl',
    group: 'arms',
    equipment: 'dumbbell',
    primaryMuscles: ['biceps'],
    secondaryMuscles: ['forearms'],
    steps: [
      'Stand with a dumbbell in each hand, palms facing forward.',
      'Curl both dumbbells up to shoulder height.',
      'Lower them slowly, all the way down, until your arms are straight.',
    ],
    tips: [
      'Keep your elbows at your sides. Only your forearms move.',
      'Lowering slowly builds as much muscle as lifting.',
    ],
  ),
  Exercise(
    id: 'barbellCurl',
    name: 'Barbell Curl',
    group: 'arms',
    equipment: 'barbell',
    primaryMuscles: ['biceps'],
    secondaryMuscles: ['forearms'],
    steps: [
      'Hold the bar about shoulder width, palms up.',
      'Curl the bar up to your shoulders without moving your elbows.',
      'Lower it slowly until your arms are straight.',
    ],
    tips: [
      'Do not swing your hips. If you must swing to lift it, the bar is too heavy.',
      'An EZ-curl bar is easier on the wrists.',
    ],
  ),
  Exercise(
    id: 'hammerCurl',
    name: 'Hammer Curl',
    group: 'arms',
    equipment: 'dumbbell',
    primaryMuscles: ['biceps', 'forearms'],
    steps: [
      'Hold the dumbbells at your sides with your palms facing your body.',
      'Curl them up while keeping your palms facing each other.',
      'Lower them slowly.',
    ],
    tips: [
      'Builds the forearms and the thickness of the upper arm.',
      'You can do both arms together or one at a time.',
    ],
  ),
  Exercise(
    id: 'preacherCurl',
    name: 'Preacher Curl',
    group: 'arms',
    equipment: 'machine',
    primaryMuscles: ['biceps'],
    steps: [
      'Sit with the backs of your upper arms flat on the pad.',
      'Curl the weight up toward your shoulders.',
      'Lower it slowly until your arms are almost straight.',
    ],
    tips: [
      'Do not bounce at the bottom. It can hurt the elbow.',
      'The pad stops swinging, so you will lift less than in a standing curl.',
    ],
  ),
  Exercise(
    id: 'concentrationCurl',
    name: 'Concentration Curl',
    group: 'arms',
    equipment: 'dumbbell',
    primaryMuscles: ['biceps'],
    steps: [
      'Sit on a bench and rest your elbow against your inner thigh.',
      'Curl the dumbbell up to your shoulder.',
      'Lower it slowly to a full stretch.',
    ],
    tips: [
      'Watch your bicep work. Focus helps the squeeze.',
      'Slow and clean is better than heavy and messy here.',
    ],
  ),
  Exercise(
    id: 'cableCurl',
    name: 'Cable Curl',
    group: 'arms',
    equipment: 'cable',
    primaryMuscles: ['biceps'],
    secondaryMuscles: ['forearms'],
    steps: [
      'Attach a straight bar to the low pulley and hold it with palms up.',
      'Curl the bar up to your shoulders with your elbows at your sides.',
      'Lower it slowly against the pull of the cable.',
    ],
    tips: [
      'The cable keeps the muscle working at the bottom, where dumbbells go easy.',
      'A good last biceps exercise for the day.',
    ],
  ),
  Exercise(
    id: 'tricepPushdown',
    name: 'Tricep Rope Pushdown',
    group: 'arms',
    equipment: 'cable',
    primaryMuscles: ['triceps'],
    steps: [
      'Face a high pulley with a rope handle, elbows at your sides.',
      'Push the rope down until your arms are straight, splitting the ends apart.',
      'Let the rope rise until your forearms pass level with the floor.',
    ],
    tips: [
      'Keep your elbows against your sides the whole set.',
      'Lean forward a little but keep your back straight.',
    ],
  ),
  Exercise(
    id: 'skullCrusher',
    name: 'Skull Crusher',
    group: 'arms',
    equipment: 'barbell',
    primaryMuscles: ['triceps'],
    steps: [
      'Lie on a bench and hold the bar over your chest with a narrow grip.',
      'Bend only at your elbows and lower the bar toward your forehead.',
      'Straighten your arms back up.',
    ],
    tips: [
      'Lower slowly to the top of your head, or just behind it.',
      'Use a light weight and stay careful. Messy form can hurt your elbows.',
    ],
  ),
  Exercise(
    id: 'overheadTricepExtension',
    name: 'Overhead Tricep Extension',
    group: 'arms',
    equipment: 'dumbbell',
    primaryMuscles: ['triceps'],
    steps: [
      'Hold one dumbbell with both hands above your head.',
      'Lower it behind your head by bending your elbows.',
      'Straighten your arms back up.',
    ],
    tips: [
      'Keep your elbows pointing forward, not out to the sides.',
      'This position works a part of the triceps that other exercises miss.',
    ],
  ),
  Exercise(
    id: 'closeGripBench',
    name: 'Close-Grip Bench Press',
    group: 'arms',
    equipment: 'barbell',
    primaryMuscles: ['triceps'],
    secondaryMuscles: ['chest', 'shoulders'],
    isCompound: true,
    steps: [
      'Lie on the bench and hold the bar about shoulder width apart.',
      'Lower the bar to your lower chest with your elbows close to your body.',
      'Push back up and focus on using your triceps.',
    ],
    tips: [
      'Use a shoulder-width grip, not hands together. Too narrow hurts the wrists.',
      'This trains your triceps with the most weight.',
    ],
  ),

  // ----- Legs -----
  Exercise(
    id: 'squat',
    name: 'Barbell Back Squat',
    group: 'legs',
    equipment: 'barbell',
    primaryMuscles: ['quads', 'glutes'],
    secondaryMuscles: ['hamstrings', 'lowerBack', 'abs'],
    isCompound: true,
    steps: [
      'Rest the bar on your upper back and step out of the rack.',
      'Set your feet about shoulder width apart, toes turned out a little.',
      'Tighten your stomach, then sit down until your thighs drop below your knees.',
      'Push back up through your whole foot.',
    ],
    tips: [
      'Keep your knees in line with your toes. Do not let them fall inward.',
      'Keep your whole foot on the floor. Your heels should not rise.',
      'Learn to go deep first. Add weight later.',
    ],
  ),
  Exercise(
    id: 'frontSquat',
    name: 'Front Squat',
    group: 'legs',
    equipment: 'barbell',
    primaryMuscles: ['quads'],
    secondaryMuscles: ['glutes', 'abs', 'upperBack'],
    isCompound: true,
    steps: [
      'Rest the bar on the front of your shoulders with your elbows high.',
      'Keep your upper body as straight as you can.',
      'Squat down until your thighs drop below your knees.',
      'Push up and keep your elbows high.',
    ],
    tips: [
      'If your wrists feel tight, cross your arms or use straps.',
      'If your elbows drop, the weight will fall forward.',
    ],
  ),
  Exercise(
    id: 'gobletSquat',
    name: 'Goblet Squat',
    group: 'legs',
    equipment: 'dumbbell',
    primaryMuscles: ['quads', 'glutes'],
    secondaryMuscles: ['abs'],
    isCompound: true,
    steps: [
      'Hold one dumbbell straight up against your chest with both hands.',
      'Squat down between your knees with your elbows inside your thighs.',
      'Stand back up tall.',
    ],
    tips: [
      'A great squat for learning depth and good posture. Perfect for beginners.',
      'Keep your chest up. The weight in front helps you balance.',
    ],
  ),
  Exercise(
    id: 'legPress',
    name: 'Leg Press',
    group: 'legs',
    equipment: 'machine',
    primaryMuscles: ['quads', 'glutes'],
    secondaryMuscles: ['hamstrings'],
    isCompound: true,
    steps: [
      'Sit in the machine with your feet about shoulder width on the platform.',
      'Release the safety locks and lower the platform toward your chest.',
      'Push back up. Do not lock your knees fully.',
    ],
    tips: [
      'Never let your lower back lift off the pad at the bottom.',
      'Placing your feet higher works more glutes and hamstrings.',
    ],
  ),
  Exercise(
    id: 'hackSquat',
    name: 'Hack Squat',
    group: 'legs',
    equipment: 'machine',
    primaryMuscles: ['quads'],
    secondaryMuscles: ['glutes'],
    isCompound: true,
    steps: [
      'Put your shoulders under the pads, feet about shoulder width apart.',
      'Release the handles and squat down until your thighs drop below your knees.',
      'Push back up through your whole foot.',
    ],
    tips: [
      'Placing your feet lower works the quads more.',
      'Go down slowly. Do not drop fast into the bottom.',
    ],
  ),
  Exercise(
    id: 'romanianDeadlift',
    name: 'Romanian Deadlift',
    group: 'legs',
    equipment: 'barbell',
    primaryMuscles: ['hamstrings', 'glutes'],
    secondaryMuscles: ['lowerBack', 'forearms'],
    isCompound: true,
    steps: [
      'Hold the bar at your thighs, feet about hip width apart.',
      'Push your hips straight back and slide the bar down your legs.',
      'Stop when you feel a strong stretch in the back of your legs, around mid shin.',
      'Push your hips forward to stand up tall.',
    ],
    tips: [
      'Keep your knees slightly bent. You bend from the hips, not into a squat.',
      'Keep your back flat. Move a shorter distance before you let it round.',
    ],
  ),
  Exercise(
    id: 'legCurl',
    name: 'Lying Leg Curl',
    group: 'legs',
    equipment: 'machine',
    primaryMuscles: ['hamstrings'],
    steps: [
      'Lie face down with the pad against your lower calves.',
      'Bend your knees and pull your heels toward your glutes.',
      'Lower slowly until your legs are straight.',
    ],
    tips: [
      'Keep your hips pressed into the bench for the whole set.',
      'Pause for one second at the top of each rep.',
    ],
  ),
  Exercise(
    id: 'legExtension',
    name: 'Leg Extension',
    group: 'legs',
    equipment: 'machine',
    primaryMuscles: ['quads'],
    steps: [
      'Sit with the pad on your lower shins, knees lined up with the machine.',
      'Straighten your legs fully.',
      'Lower slowly. Do not let the weights bang down.',
    ],
    tips: [
      'Squeeze hard for one second when your legs are straight.',
      'Use a medium weight and clean reps. This is a finishing exercise, not a max lift.',
    ],
  ),
  Exercise(
    id: 'lunge',
    name: 'Walking Lunge',
    group: 'legs',
    equipment: 'dumbbell',
    primaryMuscles: ['quads', 'glutes'],
    secondaryMuscles: ['hamstrings', 'abs'],
    isCompound: true,
    steps: [
      'Hold a dumbbell in each hand at your sides.',
      'Step forward and lower down until both knees are at 90 degrees.',
      'Push through your front foot and step into the next lunge.',
    ],
    tips: [
      'Your front knee should stay over your foot, not go past your toes.',
      'Take slightly longer steps to feel more glutes.',
    ],
  ),
  Exercise(
    id: 'bulgarianSplitSquat',
    name: 'Bulgarian Split Squat',
    group: 'legs',
    equipment: 'dumbbell',
    primaryMuscles: ['quads', 'glutes'],
    secondaryMuscles: ['hamstrings'],
    isCompound: true,
    steps: [
      'Stand one big step in front of a bench, with your back foot resting on it.',
      'Hold a dumbbell in each hand.',
      'Lower straight down until your front thigh is level with the floor.',
      'Push up through your front foot. Do the reps, then switch legs.',
    ],
    tips: [
      'These are hard, but they work well. Keep doing them.',
      'Stay upright for the quads, or lean forward a little for the glutes.',
    ],
  ),
  Exercise(
    id: 'hipThrust',
    name: 'Barbell Hip Thrust',
    group: 'legs',
    equipment: 'barbell',
    primaryMuscles: ['glutes'],
    secondaryMuscles: ['hamstrings'],
    isCompound: true,
    steps: [
      'Sit with your upper back against a bench and the bar over your hips.',
      'Put your feet flat on the floor, about shoulder width apart.',
      'Push your hips up until your body is in a straight line.',
      'Squeeze your glutes hard, then lower slowly.',
    ],
    tips: [
      'Use a pad on the bar. It protects your hip bones.',
      'Keep your chin and ribs down. Do not arch your lower back at the top.',
    ],
  ),
  Exercise(
    id: 'calfRaise',
    name: 'Standing Calf Raise',
    group: 'legs',
    equipment: 'machine',
    primaryMuscles: ['calves'],
    steps: [
      'Stand with the front of your feet on the platform and your heels hanging off.',
      'Lower your heels down for a deep stretch.',
      'Rise up onto your toes as high as you can.',
    ],
    tips: [
      'Pause for two seconds in the stretch. Do not bounce.',
      'Calves grow with full range and patience, not heavy weight.',
    ],
  ),
  Exercise(
    id: 'seatedCalfRaise',
    name: 'Seated Calf Raise',
    group: 'legs',
    equipment: 'machine',
    primaryMuscles: ['calves'],
    steps: [
      'Sit with the pads on your knees and the front of your feet on the platform.',
      'Lower your heels down to a full stretch.',
      'Push up onto your toes and squeeze.',
    ],
    tips: [
      'The bent knee works the deeper calf muscle.',
      'Slow reps and full range, every time.',
    ],
  ),

  // ----- Core -----
  Exercise(
    id: 'plank',
    name: 'Plank',
    group: 'core',
    equipment: 'bodyweight',
    primaryMuscles: ['abs'],
    secondaryMuscles: ['obliques', 'shoulders'],
    steps: [
      'Rest on your forearms and toes, with your elbows under your shoulders.',
      'Make a straight line from your head to your heels.',
      'Hold and breathe steadily. Count the seconds you hold as your reps.',
    ],
    tips: [
      'Squeeze your glutes and abs. Do not let your hips drop or rise.',
      'A short, perfect hold is better than a long, sagging one.',
    ],
  ),
  Exercise(
    id: 'sidePlank',
    name: 'Side Plank',
    group: 'core',
    equipment: 'bodyweight',
    primaryMuscles: ['obliques'],
    secondaryMuscles: ['abs', 'shoulders'],
    steps: [
      'Lie on your side, resting on one forearm, with your elbow under your shoulder.',
      'Lift your hips so your body makes a straight line.',
      'Hold, then switch sides. Count the seconds on each side as your reps.',
    ],
    tips: [
      'Push the floor away. Do not rest on your shoulder.',
      'Stack your feet, or put one in front of the other, for balance.',
    ],
  ),
  Exercise(
    id: 'crunch',
    name: 'Crunch',
    group: 'core',
    equipment: 'bodyweight',
    primaryMuscles: ['abs'],
    steps: [
      'Lie on your back with your knees bent and your hands lightly behind your head.',
      'Lift your shoulder blades off the floor.',
      'Lower slowly. Do not pull on your neck.',
    ],
    tips: [
      'Breathe out hard as you lift up.',
      'Use a small, controlled movement. This is not a full sit-up.',
    ],
  ),
  Exercise(
    id: 'cableCrunch',
    name: 'Cable Crunch',
    group: 'core',
    equipment: 'cable',
    primaryMuscles: ['abs'],
    steps: [
      'Kneel below a high pulley and hold the rope beside your head.',
      'Crunch your elbows toward your knees and round your back.',
      'Return slowly until your abs are stretched.',
    ],
    tips: [
      'Keep your hips still. Your abs round your back.',
      'This is the ab exercise where you can keep adding weight.',
    ],
  ),
  Exercise(
    id: 'legRaise',
    name: 'Hanging Leg Raise',
    group: 'core',
    equipment: 'bodyweight',
    primaryMuscles: ['abs'],
    secondaryMuscles: ['obliques', 'forearms'],
    steps: [
      'Hang from a pull-up bar with your arms straight.',
      'Lift your legs until your thighs are level with the floor.',
      'Lower them slowly. Do not swing.',
    ],
    tips: [
      'Roll your hips up at the top. Do not just lift your legs.',
      'Too hard? Start with your knees bent.',
    ],
  ),
  Exercise(
    id: 'russianTwist',
    name: 'Russian Twist',
    group: 'core',
    equipment: 'bodyweight',
    primaryMuscles: ['obliques'],
    secondaryMuscles: ['abs'],
    steps: [
      'Sit with your knees bent and lean back until you feel your abs work.',
      'Hold a weight plate or dumbbell with both hands.',
      'Turn the weight from side to side, touching near each hip.',
    ],
    tips: [
      'Turn from your ribs, not just your arms.',
      'Lift your feet off the floor to make it harder.',
    ],
  ),
  Exercise(
    id: 'abWheelRollout',
    name: 'Ab Wheel Rollout',
    group: 'core',
    equipment: 'bodyweight',
    primaryMuscles: ['abs'],
    secondaryMuscles: ['obliques', 'lats', 'shoulders'],
    steps: [
      'Kneel and hold the ab wheel under your shoulders.',
      'Roll forward as far as you can while keeping your back flat.',
      'Pull back to the start using your abs.',
    ],
    tips: [
      'Roll your hips under and squeeze your glutes before you roll out.',
      'Only roll as far as you can control. You will reach farther as you get stronger.',
    ],
  ),
  Exercise(
    id: 'deadBug',
    name: 'Dead Bug',
    group: 'core',
    equipment: 'bodyweight',
    primaryMuscles: ['abs'],
    steps: [
      'Lie on your back with your arms up and your knees bent at 90 degrees over your hips.',
      'Lower one arm and the opposite leg toward the floor.',
      'Bring them back, then repeat with the other arm and leg.',
    ],
    tips: [
      'Press your lower back into the floor the whole time.',
      'Going slowly is the point. Two seconds out, two seconds back.',
    ],
  ),

  // ----- Cardio -----
  Exercise(
    id: 'treadmillRun',
    name: 'Treadmill Run',
    group: 'cardio',
    equipment: 'machine',
    primaryMuscles: ['quads', 'hamstrings', 'calves'],
    secondaryMuscles: ['glutes'],
    steps: [
      'Start by walking, then raise the speed to an easy jog.',
      'Run tall with relaxed shoulders and a small forward lean.',
      'Count the minutes as your reps.',
    ],
    tips: [
      'At an easy pace, you should be able to speak in short sentences.',
      'A 1 percent slope feels like running outside.',
    ],
  ),
  Exercise(
    id: 'rowingMachine',
    name: 'Rowing Machine',
    group: 'cardio',
    equipment: 'machine',
    primaryMuscles: ['upperBack', 'lats', 'quads'],
    secondaryMuscles: ['biceps', 'hamstrings', 'abs'],
    steps: [
      'Strap your feet in and hold the handle with straight arms.',
      'Push with your legs first, then lean back, then pull the handle to your chest.',
      'On the way forward, do the reverse: arms, then body, then legs.',
      'Count the minutes as your reps.',
    ],
    tips: [
      'The order matters: legs, back, arms. Most beginners pull with the arms first.',
      'Most power comes from your legs, about 60 percent of each pull.',
    ],
  ),
  Exercise(
    id: 'stationaryBike',
    name: 'Stationary Bike',
    group: 'cardio',
    equipment: 'machine',
    primaryMuscles: ['quads'],
    secondaryMuscles: ['hamstrings', 'calves', 'glutes'],
    steps: [
      'Set the seat so your knee stays slightly bent at the bottom.',
      'Pedal at a steady, easy effort where you can still talk.',
      'Count the minutes as your reps.',
    ],
    tips: [
      'This is easy on your joints. Good for rest days.',
      'For intervals, go 30 seconds hard, then 90 seconds easy.',
    ],
  ),
  Exercise(
    id: 'jumpRope',
    name: 'Jump Rope',
    group: 'cardio',
    equipment: 'bodyweight',
    primaryMuscles: ['calves'],
    secondaryMuscles: ['quads', 'shoulders', 'forearms'],
    steps: [
      'Hold the handles at hip height with your elbows close to your body.',
      'Jump just high enough to clear the rope and land softly.',
      'Spin the rope with your wrists, not your arms.',
      'Count the minutes as your reps.',
    ],
    tips: [
      'Do small, quick hops on the front of your feet.',
      'Miss a jump? Keep going. Your rhythm will come within a week.',
    ],
  ),
  Exercise(
    id: 'burpee',
    name: 'Burpee',
    group: 'cardio',
    equipment: 'bodyweight',
    primaryMuscles: ['quads', 'chest'],
    secondaryMuscles: ['abs', 'shoulders', 'triceps'],
    steps: [
      'Squat down and put your hands on the floor.',
      'Kick your feet back into a push-up position and do a push-up.',
      'Jump your feet back in and jump straight up.',
    ],
    tips: [
      'Keep a steady pace. Smooth reps are better than fast, wild ones.',
      'Skip the push-up or the jump to make it easier.',
    ],
  ),
];

final Map<String, Exercise> _byId = {for (final e in exerciseLibrary) e.id: e};

Exercise exerciseById(String id) => _byId[id]!;

/// Exercises that can stand in for [id]: they train the same muscles and fill
/// the same programming role. A candidate must share at least one primary
/// muscle and match the compound-or-isolation status, so a main compound only
/// offers other compounds and an isolation only offers isolations. Ranked by
/// primary-muscle overlap, then secondary-muscle overlap, then name. Excludes
/// [id] itself and returns an empty list when nothing qualifies.
List<Exercise> similarExercises(String id) {
  final source = exerciseById(id);
  final primary = source.primaryMuscles.toSet();
  final secondary = source.secondaryMuscles.toSet();
  int primaryOverlap(Exercise e) =>
      e.primaryMuscles.where(primary.contains).length;
  int secondaryOverlap(Exercise e) =>
      e.secondaryMuscles.where(secondary.contains).length;
  final candidates = exerciseLibrary
      .where(
        (e) =>
            e.id != id &&
            e.isCompound == source.isCompound &&
            primaryOverlap(e) > 0,
      )
      .toList();
  candidates.sort((a, b) {
    final byPrimary = primaryOverlap(b).compareTo(primaryOverlap(a));
    if (byPrimary != 0) return byPrimary;
    final bySecondary = secondaryOverlap(b).compareTo(secondaryOverlap(a));
    if (bySecondary != 0) return bySecondary;
    return a.name.compareTo(b.name);
  });
  return candidates;
}

/// Stable filter-group keys in display order.
const List<String> exerciseGroups = [
  'chest',
  'back',
  'shoulders',
  'arms',
  'legs',
  'core',
  'cardio',
];
