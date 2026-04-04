import SceneKit

// MARK: - Species Model

struct SpeciesModel {
    let rootNode: SCNNode
    let headNode: SCNNode
    let leftEyeNode: SCNNode
    let rightEyeNode: SCNNode
    let mouthNode: SCNNode?
    let hatAttachPoint: SCNVector3
    let boundingHeight: Float

    // Optional species-specific nodes
    var tailNode: SCNNode?
    var accessoryNodes: [String: SCNNode] = [:]
}

// MARK: - PBR Material Helper

private func makeMaterial(color: NSColor, roughness: Float = 0.7, metalness: Float = 0.1) -> SCNMaterial {
    let mat = SCNMaterial()
    mat.diffuse.contents = color
    mat.roughness.contents = NSNumber(value: roughness)
    mat.metalness.contents = NSNumber(value: metalness)
    mat.lightingModel = .physicallyBased
    return mat
}

private func makeShinyMaterial(color: NSColor) -> SCNMaterial {
    let mat = makeMaterial(color: color, roughness: 0.4, metalness: 0.5)
    mat.emission.contents = color.withAlphaComponent(0.3)
    return mat
}

// MARK: - Eye Builder

private func buildEye(radius: Float = 0.08, color: NSColor = .white, pupilColor: NSColor = .black) -> SCNNode {
    let eyeNode = SCNNode()

    let whiteSphere = SCNSphere(radius: CGFloat(radius))
    whiteSphere.firstMaterial = makeMaterial(color: color, roughness: 0.3, metalness: 0.0)
    let whiteNode = SCNNode(geometry: whiteSphere)
    eyeNode.addChildNode(whiteNode)

    let pupilSphere = SCNSphere(radius: CGFloat(radius * 0.5))
    pupilSphere.firstMaterial = makeMaterial(color: pupilColor, roughness: 0.9, metalness: 0.0)
    let pupilNode = SCNNode(geometry: pupilSphere)
    pupilNode.name = "pupil"
    pupilNode.position = SCNVector3(0, 0, radius * 0.6)
    eyeNode.addChildNode(pupilNode)

    return eyeNode
}

// MARK: - Species Model Builder

class SpeciesModelBuilder {
    static let shared = SpeciesModelBuilder()

    func build(species: String, shiny: Bool = false) -> SpeciesModel {
        switch species {
        case "duck":     return buildDuck(shiny: shiny)
        case "goose":    return buildGoose(shiny: shiny)
        case "blob":     return buildBlob(shiny: shiny)
        case "cat":      return buildCat(shiny: shiny)
        case "dragon":   return buildDragon(shiny: shiny)
        case "octopus":  return buildOctopus(shiny: shiny)
        case "owl":      return buildOwl(shiny: shiny)
        case "penguin":  return buildPenguin(shiny: shiny)
        case "turtle":   return buildTurtle(shiny: shiny)
        case "snail":    return buildSnail(shiny: shiny)
        case "ghost":    return buildGhost(shiny: shiny)
        case "axolotl":  return buildAxolotl(shiny: shiny)
        case "capybara": return buildCapybara(shiny: shiny)
        case "cactus":   return buildCactus(shiny: shiny)
        case "robot":    return buildRobot(shiny: shiny)
        case "rabbit":   return buildRabbit(shiny: shiny)
        case "mushroom": return buildMushroom(shiny: shiny)
        case "chonk":    return buildChonk(shiny: shiny)
        default:         return buildBlob(shiny: shiny)
        }
    }

    // MARK: - Material Helper

    private func mat(_ color: NSColor, shiny: Bool) -> SCNMaterial {
        return shiny ? makeShinyMaterial(color: color) : makeMaterial(color: color)
    }

    // MARK: - Duck

    private func buildDuck(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemYellow : NSColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)

        // Body - capsule
        let body = SCNCapsule(capRadius: 0.4, height: 0.9)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.45, 0)
        root.addChildNode(bodyNode)

        // Head - sphere
        let head = SCNSphere(radius: 0.35)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.1, 0.1)
        root.addChildNode(headNode)

        // Beak - cone
        let beak = SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.2)
        beak.firstMaterial = mat(NSColor.orange, shiny: shiny)
        let beakNode = SCNNode(geometry: beak)
        beakNode.position = SCNVector3(0, 1.05, 0.4)
        beakNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        headNode.addChildNode(beakNode)

        // Eyes
        let leftEye = buildEye()
        leftEye.position = SCNVector3(-0.12, 1.18, 0.3)
        root.addChildNode(leftEye)

        let rightEye = buildEye()
        rightEye.position = SCNVector3(0.12, 1.18, 0.3)
        root.addChildNode(rightEye)

        // Feet - small cylinders
        let footMat = mat(NSColor.orange, shiny: shiny)
        for xOff: Float in [-0.15, 0.15] {
            let foot = SCNCylinder(radius: 0.08, height: 0.04)
            foot.firstMaterial = footMat
            let footNode = SCNNode(geometry: foot)
            footNode.position = SCNVector3(xOff, 0.02, 0.05)
            root.addChildNode(footNode)
        }

        // Tail feathers
        let tail = SCNCone(topRadius: 0, bottomRadius: 0.12, height: 0.2)
        tail.firstMaterial = mat(bodyColor, shiny: shiny)
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(0, 0.6, -0.35)
        tailNode.eulerAngles = SCNVector3(Float.pi / 4, 0, 0)
        root.addChildNode(tailNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: beakNode, hatAttachPoint: SCNVector3(0, 1.45, 0),
            boundingHeight: 1.5, tailNode: tailNode
        )
    }

    // MARK: - Cat

    private func buildCat(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemPurple : NSColor(white: 0.5, alpha: 1.0)

        // Body
        let body = SCNCapsule(capRadius: 0.35, height: 0.8)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(bodyNode)

        // Head - larger sphere
        let head = SCNSphere(radius: 0.38)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.05, 0.05)
        root.addChildNode(headNode)

        // Ears - cones with pink inner
        let earColor = mat(bodyColor, shiny: shiny)
        let pinkMat = mat(NSColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 1.0), shiny: shiny)
        for xOff: Float in [-0.22, 0.22] {
            let ear = SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.2)
            ear.firstMaterial = earColor
            let earNode = SCNNode(geometry: ear)
            earNode.position = SCNVector3(xOff, 1.4, 0)
            root.addChildNode(earNode)

            let inner = SCNCone(topRadius: 0, bottomRadius: 0.06, height: 0.12)
            inner.firstMaterial = pinkMat
            let innerNode = SCNNode(geometry: inner)
            innerNode.position = SCNVector3(0, -0.02, 0.03)
            earNode.addChildNode(innerNode)
        }

        // Eyes
        let leftEye = buildEye(radius: 0.09)
        leftEye.position = SCNVector3(-0.15, 1.12, 0.32)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.09)
        rightEye.position = SCNVector3(0.15, 1.12, 0.32)
        root.addChildNode(rightEye)

        // Nose/mouth
        let nose = SCNSphere(radius: 0.03)
        nose.firstMaterial = mat(NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0), shiny: shiny)
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(0, 1.0, 0.38)
        root.addChildNode(noseNode)

        // Whiskers - thin cylinders
        let whiskerMat = mat(NSColor(white: 0.8, alpha: 1.0), shiny: shiny)
        for (xSign, zRot) in [(Float(-1), Float(0.1)), (Float(1), Float(-0.1))] {
            for yOff: Float in [-0.02, 0.02] {
                let whisker = SCNCylinder(radius: 0.005, height: 0.2)
                whisker.firstMaterial = whiskerMat
                let wNode = SCNNode(geometry: whisker)
                wNode.position = SCNVector3(xSign * 0.25, 1.0 + yOff, 0.3)
                wNode.eulerAngles = SCNVector3(0, 0, zRot + xSign * 0.3)
                root.addChildNode(wNode)
            }
        }

        // Tail
        let tail = SCNCapsule(capRadius: 0.04, height: 0.5)
        tail.firstMaterial = mat(bodyColor, shiny: shiny)
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(0, 0.4, -0.35)
        tailNode.eulerAngles = SCNVector3(-0.5, 0.3, 0)
        root.addChildNode(tailNode)

        // Paws
        let pawMat = mat(bodyColor, shiny: shiny)
        for xOff: Float in [-0.12, 0.12] {
            let paw = SCNSphere(radius: 0.08)
            paw.firstMaterial = pawMat
            let pawNode = SCNNode(geometry: paw)
            pawNode.position = SCNVector3(xOff, 0.04, 0.05)
            root.addChildNode(pawNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: noseNode, hatAttachPoint: SCNVector3(0, 1.42, 0),
            boundingHeight: 1.6, tailNode: tailNode
        )
    }

    // MARK: - Snail

    private func buildSnail(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemMint : NSColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        let shellColor = shiny ? NSColor.systemTeal : NSColor(red: 0.6, green: 0.4, blue: 0.25, alpha: 1.0)

        // Body / foot - capsule
        let body = SCNCapsule(capRadius: 0.2, height: 0.8)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.2, 0)
        bodyNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        root.addChildNode(bodyNode)

        // Shell - sphere
        let shell = SCNSphere(radius: 0.4)
        shell.firstMaterial = mat(shellColor, shiny: shiny)
        let shellNode = SCNNode(geometry: shell)
        shellNode.position = SCNVector3(-0.1, 0.55, 0)
        root.addChildNode(shellNode)

        // Shell spiral - torus
        let spiral = SCNTorus(ringRadius: 0.2, pipeRadius: 0.05)
        spiral.firstMaterial = mat(shellColor.blended(withFraction: 0.3, of: .white) ?? shellColor, shiny: shiny)
        let spiralNode = SCNNode(geometry: spiral)
        spiralNode.position = SCNVector3(0, 0, 0)
        spiralNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        shellNode.addChildNode(spiralNode)

        // Head
        let head = SCNSphere(radius: 0.18)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0.35, 0.4, 0)
        root.addChildNode(headNode)

        // Eye stalks
        let stalkMat = mat(bodyColor, shiny: shiny)
        let leftEye = buildEye(radius: 0.06)
        let rightEye = buildEye(radius: 0.06)

        let leftStalk = SCNCylinder(radius: 0.02, height: 0.2)
        leftStalk.firstMaterial = stalkMat
        let leftStalkNode = SCNNode(geometry: leftStalk)
        leftStalkNode.position = SCNVector3(0.35 - 0.06, 0.65, 0.05)
        root.addChildNode(leftStalkNode)
        leftEye.position = SCNVector3(0.35 - 0.06, 0.78, 0.05)
        root.addChildNode(leftEye)

        let rightStalk = SCNCylinder(radius: 0.02, height: 0.2)
        rightStalk.firstMaterial = stalkMat
        let rightStalkNode = SCNNode(geometry: rightStalk)
        rightStalkNode.position = SCNVector3(0.35 + 0.06, 0.65, 0.05)
        root.addChildNode(rightStalkNode)
        rightEye.position = SCNVector3(0.35 + 0.06, 0.78, 0.05)
        root.addChildNode(rightEye)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: nil, hatAttachPoint: SCNVector3(0.35, 0.85, 0),
            boundingHeight: 1.0
        )
    }

    // MARK: - Goose

    private func buildGoose(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemCyan : NSColor.white

        // Body
        let body = SCNCapsule(capRadius: 0.35, height: 0.8)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(bodyNode)

        // Neck - cylinder
        let neck = SCNCylinder(radius: 0.08, height: 0.5)
        neck.firstMaterial = mat(bodyColor, shiny: shiny)
        let neckNode = SCNNode(geometry: neck)
        neckNode.position = SCNVector3(0.05, 1.0, 0.1)
        root.addChildNode(neckNode)

        // Head
        let head = SCNSphere(radius: 0.2)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0.05, 1.35, 0.1)
        root.addChildNode(headNode)

        // Beak
        let beak = SCNCone(topRadius: 0, bottomRadius: 0.08, height: 0.18)
        beak.firstMaterial = mat(NSColor.orange, shiny: shiny)
        let beakNode = SCNNode(geometry: beak)
        beakNode.position = SCNVector3(0, -0.05, 0.2)
        beakNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        headNode.addChildNode(beakNode)

        let leftEye = buildEye(radius: 0.05)
        leftEye.position = SCNVector3(-0.08, 1.4, 0.22)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.05)
        rightEye.position = SCNVector3(0.18, 1.4, 0.22)
        root.addChildNode(rightEye)

        // Feet
        for xOff: Float in [-0.12, 0.12] {
            let foot = SCNCylinder(radius: 0.08, height: 0.03)
            foot.firstMaterial = mat(NSColor.orange, shiny: shiny)
            let fNode = SCNNode(geometry: foot)
            fNode.position = SCNVector3(xOff, 0.015, 0.05)
            root.addChildNode(fNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: beakNode, hatAttachPoint: SCNVector3(0.05, 1.55, 0.1),
            boundingHeight: 1.6
        )
    }

    // MARK: - Blob

    private func buildBlob(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemPink : NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)

        let body = SCNSphere(radius: 0.55)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.5, 0)
        bodyNode.scale = SCNVector3(1.0, 0.85, 0.9)
        root.addChildNode(bodyNode)

        let headNode = bodyNode // blob is all one piece

        let leftEye = buildEye(radius: 0.08)
        leftEye.position = SCNVector3(-0.18, 0.6, 0.42)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.08)
        rightEye.position = SCNVector3(0.18, 0.6, 0.42)
        root.addChildNode(rightEye)

        // Mouth
        let mouth = SCNCylinder(radius: 0.08, height: 0.01)
        mouth.firstMaterial = mat(NSColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1.0), shiny: shiny)
        let mouthNode = SCNNode(geometry: mouth)
        mouthNode.position = SCNVector3(0, 0.42, 0.48)
        mouthNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        root.addChildNode(mouthNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: mouthNode, hatAttachPoint: SCNVector3(0, 1.0, 0),
            boundingHeight: 1.1
        )
    }

    // MARK: - Dragon

    private func buildDragon(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemRed : NSColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)

        let body = SCNCapsule(capRadius: 0.38, height: 0.85)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.42, 0)
        root.addChildNode(bodyNode)

        let head = SCNSphere(radius: 0.32)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.1, 0.05)
        root.addChildNode(headNode)

        // Horns
        for xOff: Float in [-0.2, 0.2] {
            let horn = SCNCone(topRadius: 0, bottomRadius: 0.06, height: 0.25)
            horn.firstMaterial = mat(NSColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0), shiny: shiny)
            let hNode = SCNNode(geometry: horn)
            hNode.position = SCNVector3(xOff, 1.4, -0.05)
            hNode.eulerAngles = SCNVector3(0, 0, xOff < 0 ? 0.2 : -0.2)
            root.addChildNode(hNode)
        }

        let leftEye = buildEye(radius: 0.07, pupilColor: NSColor(red: 1.0, green: 0.5, blue: 0, alpha: 1.0))
        leftEye.position = SCNVector3(-0.14, 1.18, 0.28)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.07, pupilColor: NSColor(red: 1.0, green: 0.5, blue: 0, alpha: 1.0))
        rightEye.position = SCNVector3(0.14, 1.18, 0.28)
        root.addChildNode(rightEye)

        // Snout
        let snout = SCNCone(topRadius: 0.08, bottomRadius: 0.12, height: 0.15)
        snout.firstMaterial = mat(bodyColor, shiny: shiny)
        let snoutNode = SCNNode(geometry: snout)
        snoutNode.position = SCNVector3(0, 1.02, 0.35)
        snoutNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        root.addChildNode(snoutNode)

        // Wings
        let wingMat = mat(bodyColor.blended(withFraction: 0.2, of: .black) ?? bodyColor, shiny: shiny)
        for xSign: Float in [-1, 1] {
            let wing = SCNCone(topRadius: 0, bottomRadius: 0.3, height: 0.4)
            wing.firstMaterial = wingMat
            let wNode = SCNNode(geometry: wing)
            wNode.position = SCNVector3(xSign * 0.4, 0.7, -0.15)
            wNode.eulerAngles = SCNVector3(0, 0, xSign * 0.8)
            root.addChildNode(wNode)
        }

        // Tail
        let tail = SCNCapsule(capRadius: 0.05, height: 0.5)
        tail.firstMaterial = mat(bodyColor, shiny: shiny)
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(0, 0.3, -0.4)
        tailNode.eulerAngles = SCNVector3(-0.6, 0, 0)
        root.addChildNode(tailNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: snoutNode, hatAttachPoint: SCNVector3(0, 1.45, 0),
            boundingHeight: 1.6, tailNode: tailNode
        )
    }

    // MARK: - Octopus

    private func buildOctopus(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemIndigo : NSColor(red: 0.7, green: 0.3, blue: 0.6, alpha: 1.0)

        let head = SCNSphere(radius: 0.45)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 0.8, 0)
        headNode.scale = SCNVector3(1.0, 1.1, 0.9)
        root.addChildNode(headNode)

        let leftEye = buildEye(radius: 0.09)
        leftEye.position = SCNVector3(-0.18, 0.9, 0.35)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.09)
        rightEye.position = SCNVector3(0.18, 0.9, 0.35)
        root.addChildNode(rightEye)

        // Tentacles - 8 capsules arranged in a circle
        let tentMat = mat(bodyColor, shiny: shiny)
        for i in 0..<8 {
            let angle = Float(i) * Float.pi / 4.0
            let tent = SCNCapsule(capRadius: 0.05, height: 0.45)
            tent.firstMaterial = tentMat
            let tNode = SCNNode(geometry: tent)
            let x = sin(angle) * 0.25
            let z = cos(angle) * 0.25
            tNode.position = SCNVector3(x, 0.2, z)
            tNode.eulerAngles = SCNVector3(cos(angle) * 0.3, 0, -sin(angle) * 0.3)
            root.addChildNode(tNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: nil, hatAttachPoint: SCNVector3(0, 1.3, 0),
            boundingHeight: 1.3
        )
    }

    // MARK: - Owl

    private func buildOwl(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemOrange : NSColor(red: 0.55, green: 0.35, blue: 0.2, alpha: 1.0)

        let body = SCNCapsule(capRadius: 0.35, height: 0.7)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(bodyNode)

        // Belly
        let belly = SCNSphere(radius: 0.28)
        belly.firstMaterial = mat(NSColor(red: 0.85, green: 0.75, blue: 0.6, alpha: 1.0), shiny: shiny)
        let bellyNode = SCNNode(geometry: belly)
        bellyNode.position = SCNVector3(0, 0.3, 0.12)
        bellyNode.scale = SCNVector3(0.8, 0.9, 0.5)
        root.addChildNode(bellyNode)

        let head = SCNSphere(radius: 0.35)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.0, 0)
        root.addChildNode(headNode)

        // Ear tufts
        for xOff: Float in [-0.2, 0.2] {
            let tuft = SCNCone(topRadius: 0, bottomRadius: 0.08, height: 0.2)
            tuft.firstMaterial = mat(bodyColor, shiny: shiny)
            let tNode = SCNNode(geometry: tuft)
            tNode.position = SCNVector3(xOff, 1.32, 0)
            root.addChildNode(tNode)
        }

        // Big eyes with rings
        let leftEye = buildEye(radius: 0.12)
        leftEye.position = SCNVector3(-0.15, 1.08, 0.28)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.12)
        rightEye.position = SCNVector3(0.15, 1.08, 0.28)
        root.addChildNode(rightEye)

        // Beak
        let beak = SCNCone(topRadius: 0, bottomRadius: 0.06, height: 0.1)
        beak.firstMaterial = mat(NSColor(red: 0.9, green: 0.7, blue: 0.2, alpha: 1.0), shiny: shiny)
        let beakNode = SCNNode(geometry: beak)
        beakNode.position = SCNVector3(0, 0.95, 0.35)
        beakNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, Float.pi)
        root.addChildNode(beakNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: beakNode, hatAttachPoint: SCNVector3(0, 1.38, 0),
            boundingHeight: 1.5
        )
    }

    // MARK: - Penguin

    private func buildPenguin(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemBlue : NSColor(white: 0.15, alpha: 1.0)

        let body = SCNCapsule(capRadius: 0.35, height: 0.8)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(bodyNode)

        // White belly
        let belly = SCNSphere(radius: 0.3)
        belly.firstMaterial = mat(.white, shiny: shiny)
        let bellyNode = SCNNode(geometry: belly)
        bellyNode.position = SCNVector3(0, 0.4, 0.1)
        bellyNode.scale = SCNVector3(0.75, 1.0, 0.5)
        root.addChildNode(bellyNode)

        let head = SCNSphere(radius: 0.3)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.0, 0)
        root.addChildNode(headNode)

        let leftEye = buildEye(radius: 0.06)
        leftEye.position = SCNVector3(-0.12, 1.08, 0.24)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.06)
        rightEye.position = SCNVector3(0.12, 1.08, 0.24)
        root.addChildNode(rightEye)

        let beak = SCNCone(topRadius: 0, bottomRadius: 0.07, height: 0.14)
        beak.firstMaterial = mat(NSColor.orange, shiny: shiny)
        let beakNode = SCNNode(geometry: beak)
        beakNode.position = SCNVector3(0, 0.98, 0.3)
        beakNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        root.addChildNode(beakNode)

        // Flippers
        for xSign: Float in [-1, 1] {
            let flipper = SCNCapsule(capRadius: 0.06, height: 0.3)
            flipper.firstMaterial = mat(bodyColor, shiny: shiny)
            let fNode = SCNNode(geometry: flipper)
            fNode.position = SCNVector3(xSign * 0.35, 0.5, 0)
            fNode.eulerAngles = SCNVector3(0, 0, xSign * 0.3)
            root.addChildNode(fNode)
        }

        // Feet
        for xOff: Float in [-0.1, 0.1] {
            let foot = SCNCylinder(radius: 0.08, height: 0.03)
            foot.firstMaterial = mat(NSColor.orange, shiny: shiny)
            let fNode = SCNNode(geometry: foot)
            fNode.position = SCNVector3(xOff, 0.015, 0.08)
            root.addChildNode(fNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: beakNode, hatAttachPoint: SCNVector3(0, 1.32, 0),
            boundingHeight: 1.4
        )
    }

    // MARK: - Turtle

    private func buildTurtle(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemGreen : NSColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 1.0)
        let shellColor = shiny ? NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0) : NSColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)

        // Shell
        let shell = SCNSphere(radius: 0.5)
        shell.firstMaterial = mat(shellColor, shiny: shiny)
        let shellNode = SCNNode(geometry: shell)
        shellNode.position = SCNVector3(0, 0.35, 0)
        shellNode.scale = SCNVector3(1.0, 0.6, 0.85)
        root.addChildNode(shellNode)

        // Head
        let head = SCNSphere(radius: 0.2)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0.3, 0.45, 0)
        root.addChildNode(headNode)

        let leftEye = buildEye(radius: 0.05)
        leftEye.position = SCNVector3(0.32, 0.52, 0.14)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.05)
        rightEye.position = SCNVector3(0.42, 0.52, 0.08)
        root.addChildNode(rightEye)

        // Legs
        let legMat = mat(bodyColor, shiny: shiny)
        let legPositions: [(Float, Float)] = [(-0.3, 0.2), (0.3, 0.2), (-0.3, -0.2), (0.3, -0.2)]
        for (x, z) in legPositions {
            let leg = SCNCapsule(capRadius: 0.06, height: 0.15)
            leg.firstMaterial = legMat
            let lNode = SCNNode(geometry: leg)
            lNode.position = SCNVector3(x, 0.08, z)
            root.addChildNode(lNode)
        }

        // Tail
        let tail = SCNCone(topRadius: 0.03, bottomRadius: 0.01, height: 0.12)
        tail.firstMaterial = mat(bodyColor, shiny: shiny)
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(-0.4, 0.3, 0)
        tailNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
        root.addChildNode(tailNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: nil, hatAttachPoint: SCNVector3(0.3, 0.7, 0),
            boundingHeight: 0.9, tailNode: tailNode
        )
    }

    // MARK: - Ghost

    private func buildGhost(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.8) : NSColor(white: 0.95, alpha: 0.85)

        // Body - elongated sphere
        let body = SCNCapsule(capRadius: 0.4, height: 0.7)
        let bodyMat = mat(bodyColor, shiny: shiny)
        bodyMat.transparency = 0.85
        body.firstMaterial = bodyMat
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.5, 0)
        root.addChildNode(bodyNode)

        let headNode = bodyNode

        // Wavy bottom
        for i in 0..<5 {
            let wave = SCNCone(topRadius: 0.08, bottomRadius: 0, height: 0.15)
            let waveMat = mat(bodyColor, shiny: shiny)
            waveMat.transparency = 0.85
            wave.firstMaterial = waveMat
            let wNode = SCNNode(geometry: wave)
            let x = Float(i - 2) * 0.15
            wNode.position = SCNVector3(x, 0.05, 0)
            wNode.eulerAngles = SCNVector3(Float.pi, 0, 0)
            root.addChildNode(wNode)
        }

        let leftEye = buildEye(radius: 0.08, pupilColor: .black)
        leftEye.position = SCNVector3(-0.15, 0.65, 0.35)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.08, pupilColor: .black)
        rightEye.position = SCNVector3(0.15, 0.65, 0.35)
        root.addChildNode(rightEye)

        // Mouth - O shape
        let mouth = SCNTorus(ringRadius: 0.06, pipeRadius: 0.015)
        mouth.firstMaterial = mat(NSColor(white: 0.3, alpha: 1.0), shiny: shiny)
        let mouthNode = SCNNode(geometry: mouth)
        mouthNode.position = SCNVector3(0, 0.48, 0.38)
        mouthNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        root.addChildNode(mouthNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: mouthNode, hatAttachPoint: SCNVector3(0, 1.05, 0),
            boundingHeight: 1.2
        )
    }

    // MARK: - Axolotl

    private func buildAxolotl(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemPink : NSColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0)

        let body = SCNCapsule(capRadius: 0.3, height: 0.8)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(bodyNode)

        let head = SCNSphere(radius: 0.32)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 0.95, 0)
        root.addChildNode(headNode)

        // Gills - 3 branches on each side
        let gillMat = mat(NSColor(red: 0.9, green: 0.3, blue: 0.5, alpha: 1.0), shiny: shiny)
        for xSign: Float in [-1, 1] {
            for j in 0..<3 {
                let gill = SCNCapsule(capRadius: 0.02, height: 0.2)
                gill.firstMaterial = gillMat
                let gNode = SCNNode(geometry: gill)
                let angle = Float(j - 1) * 0.4
                gNode.position = SCNVector3(xSign * 0.3, 1.15, -0.05)
                gNode.eulerAngles = SCNVector3(angle * 0.3, 0, xSign * (0.5 + Float(j) * 0.2))
                root.addChildNode(gNode)
            }
        }

        let leftEye = buildEye(radius: 0.07)
        leftEye.position = SCNVector3(-0.15, 1.02, 0.25)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.07)
        rightEye.position = SCNVector3(0.15, 1.02, 0.25)
        root.addChildNode(rightEye)

        let mouth = SCNCylinder(radius: 0.1, height: 0.01)
        mouth.firstMaterial = mat(NSColor(red: 0.9, green: 0.5, blue: 0.6, alpha: 1.0), shiny: shiny)
        let mouthNode = SCNNode(geometry: mouth)
        mouthNode.position = SCNVector3(0, 0.88, 0.3)
        mouthNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        root.addChildNode(mouthNode)

        // Tail
        let tail = SCNCapsule(capRadius: 0.05, height: 0.5)
        tail.firstMaterial = mat(bodyColor, shiny: shiny)
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(0, 0.2, -0.35)
        tailNode.eulerAngles = SCNVector3(-0.5, 0, 0)
        root.addChildNode(tailNode)

        // Legs
        for (x, z) in [(Float(-0.25), Float(0.1)), (Float(0.25), Float(0.1)), (Float(-0.25), Float(-0.15)), (Float(0.25), Float(-0.15))] {
            let leg = SCNCapsule(capRadius: 0.04, height: 0.15)
            leg.firstMaterial = mat(bodyColor, shiny: shiny)
            let lNode = SCNNode(geometry: leg)
            lNode.position = SCNVector3(x, 0.1, z)
            root.addChildNode(lNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: mouthNode, hatAttachPoint: SCNVector3(0, 1.3, 0),
            boundingHeight: 1.4, tailNode: tailNode
        )
    }

    // MARK: - Capybara

    private func buildCapybara(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemBrown : NSColor(red: 0.55, green: 0.4, blue: 0.3, alpha: 1.0)

        let body = SCNCapsule(capRadius: 0.4, height: 0.8)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.4, 0)
        root.addChildNode(bodyNode)

        let head = SCNSphere(radius: 0.3)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.0, 0.1)
        root.addChildNode(headNode)

        // Ears
        for xOff: Float in [-0.18, 0.18] {
            let ear = SCNSphere(radius: 0.06)
            ear.firstMaterial = mat(bodyColor, shiny: shiny)
            let eNode = SCNNode(geometry: ear)
            eNode.position = SCNVector3(xOff, 1.28, 0.05)
            root.addChildNode(eNode)
        }

        let leftEye = buildEye(radius: 0.06)
        leftEye.position = SCNVector3(-0.12, 1.08, 0.3)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.06)
        rightEye.position = SCNVector3(0.12, 1.08, 0.3)
        root.addChildNode(rightEye)

        // Nose
        let nose = SCNSphere(radius: 0.08)
        nose.firstMaterial = mat(NSColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0), shiny: shiny)
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(0, 0.98, 0.35)
        root.addChildNode(noseNode)

        // Legs
        for (x, z) in [(Float(-0.2), Float(0.1)), (Float(0.2), Float(0.1)), (Float(-0.2), Float(-0.1)), (Float(0.2), Float(-0.1))] {
            let leg = SCNCapsule(capRadius: 0.06, height: 0.2)
            leg.firstMaterial = mat(bodyColor, shiny: shiny)
            let lNode = SCNNode(geometry: leg)
            lNode.position = SCNVector3(x, 0.1, z)
            root.addChildNode(lNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: noseNode, hatAttachPoint: SCNVector3(0, 1.35, 0),
            boundingHeight: 1.4
        )
    }

    // MARK: - Cactus

    private func buildCactus(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemMint : NSColor(red: 0.2, green: 0.65, blue: 0.3, alpha: 1.0)

        // Main body
        let body = SCNCylinder(radius: 0.25, height: 1.0)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.5, 0)
        root.addChildNode(bodyNode)

        // Arms
        for xSign: Float in [-1, 1] {
            let arm = SCNCapsule(capRadius: 0.1, height: 0.35)
            arm.firstMaterial = mat(bodyColor, shiny: shiny)
            let aNode = SCNNode(geometry: arm)
            aNode.position = SCNVector3(xSign * 0.3, 0.55, 0)
            aNode.eulerAngles = SCNVector3(0, 0, xSign * 0.8)
            root.addChildNode(aNode)
        }

        let headNode = bodyNode

        let leftEye = buildEye(radius: 0.06)
        leftEye.position = SCNVector3(-0.1, 0.8, 0.22)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.06)
        rightEye.position = SCNVector3(0.1, 0.8, 0.22)
        root.addChildNode(rightEye)

        // Flower on top
        let flower = SCNSphere(radius: 0.08)
        flower.firstMaterial = mat(NSColor(red: 1.0, green: 0.4, blue: 0.5, alpha: 1.0), shiny: shiny)
        let flowerNode = SCNNode(geometry: flower)
        flowerNode.position = SCNVector3(0.08, 1.05, 0)
        root.addChildNode(flowerNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: nil, hatAttachPoint: SCNVector3(0, 1.1, 0),
            boundingHeight: 1.2
        )
    }

    // MARK: - Robot

    private func buildRobot(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemCyan : NSColor(white: 0.6, alpha: 1.0)

        // Body - box
        let body = SCNBox(width: 0.6, height: 0.5, length: 0.4, chamferRadius: 0.05)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(bodyNode)

        // Head - box
        let head = SCNBox(width: 0.5, height: 0.4, length: 0.35, chamferRadius: 0.05)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 0.85, 0)
        root.addChildNode(headNode)

        // Antenna
        let antenna = SCNCylinder(radius: 0.02, height: 0.15)
        antenna.firstMaterial = mat(NSColor(white: 0.4, alpha: 1.0), shiny: shiny)
        let aNode = SCNNode(geometry: antenna)
        aNode.position = SCNVector3(0, 1.12, 0)
        root.addChildNode(aNode)

        let tip = SCNSphere(radius: 0.04)
        tip.firstMaterial = mat(NSColor.systemRed, shiny: shiny)
        let tipNode = SCNNode(geometry: tip)
        tipNode.position = SCNVector3(0, 1.22, 0)
        root.addChildNode(tipNode)

        let leftEye = buildEye(radius: 0.07, color: NSColor.systemGreen, pupilColor: NSColor(white: 0.1, alpha: 1.0))
        leftEye.position = SCNVector3(-0.12, 0.9, 0.16)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.07, color: NSColor.systemGreen, pupilColor: NSColor(white: 0.1, alpha: 1.0))
        rightEye.position = SCNVector3(0.12, 0.9, 0.16)
        root.addChildNode(rightEye)

        // Mouth - horizontal line
        let mouth = SCNBox(width: 0.2, height: 0.02, length: 0.02, chamferRadius: 0)
        mouth.firstMaterial = mat(NSColor(white: 0.3, alpha: 1.0), shiny: shiny)
        let mouthNode = SCNNode(geometry: mouth)
        mouthNode.position = SCNVector3(0, 0.75, 0.18)
        root.addChildNode(mouthNode)

        // Arms
        for xSign: Float in [-1, 1] {
            let arm = SCNCapsule(capRadius: 0.05, height: 0.3)
            arm.firstMaterial = mat(bodyColor, shiny: shiny)
            let armNode = SCNNode(geometry: arm)
            armNode.position = SCNVector3(xSign * 0.38, 0.35, 0)
            root.addChildNode(armNode)
        }

        // Legs
        for xOff: Float in [-0.15, 0.15] {
            let leg = SCNCapsule(capRadius: 0.06, height: 0.2)
            leg.firstMaterial = mat(bodyColor, shiny: shiny)
            let lNode = SCNNode(geometry: leg)
            lNode.position = SCNVector3(xOff, 0.08, 0)
            root.addChildNode(lNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: mouthNode, hatAttachPoint: SCNVector3(0, 1.25, 0),
            boundingHeight: 1.3
        )
    }

    // MARK: - Rabbit

    private func buildRabbit(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemPink : NSColor(white: 0.9, alpha: 1.0)

        let body = SCNCapsule(capRadius: 0.3, height: 0.6)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(bodyNode)

        let head = SCNSphere(radius: 0.3)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 0.95, 0)
        root.addChildNode(headNode)

        // Long ears
        let earMat = mat(bodyColor, shiny: shiny)
        let pinkMat = mat(NSColor(red: 1.0, green: 0.7, blue: 0.8, alpha: 1.0), shiny: shiny)
        for xOff: Float in [-0.1, 0.1] {
            let ear = SCNCapsule(capRadius: 0.06, height: 0.35)
            ear.firstMaterial = earMat
            let eNode = SCNNode(geometry: ear)
            eNode.position = SCNVector3(xOff, 1.4, -0.02)
            eNode.eulerAngles = SCNVector3(0, 0, xOff < 0 ? 0.1 : -0.1)
            root.addChildNode(eNode)

            let inner = SCNCapsule(capRadius: 0.03, height: 0.25)
            inner.firstMaterial = pinkMat
            let iNode = SCNNode(geometry: inner)
            iNode.position = SCNVector3(0, 0, 0.04)
            eNode.addChildNode(iNode)
        }

        let leftEye = buildEye(radius: 0.07)
        leftEye.position = SCNVector3(-0.12, 1.02, 0.25)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.07)
        rightEye.position = SCNVector3(0.12, 1.02, 0.25)
        root.addChildNode(rightEye)

        // Nose
        let nose = SCNSphere(radius: 0.03)
        nose.firstMaterial = mat(NSColor(red: 1.0, green: 0.5, blue: 0.6, alpha: 1.0), shiny: shiny)
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(0, 0.92, 0.3)
        root.addChildNode(noseNode)

        // Fluffy tail
        let tail = SCNSphere(radius: 0.08)
        tail.firstMaterial = mat(bodyColor, shiny: shiny)
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(0, 0.25, -0.25)
        root.addChildNode(tailNode)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: noseNode, hatAttachPoint: SCNVector3(0, 1.28, 0),
            boundingHeight: 1.6, tailNode: tailNode
        )
    }

    // MARK: - Mushroom

    private func buildMushroom(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let capColor = shiny ? NSColor.systemPurple : NSColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1.0)
        let stemColor = shiny ? NSColor.systemYellow : NSColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0)

        // Cap - flattened sphere
        let cap = SCNSphere(radius: 0.5)
        cap.firstMaterial = mat(capColor, shiny: shiny)
        let capNode = SCNNode(geometry: cap)
        capNode.position = SCNVector3(0, 0.85, 0)
        capNode.scale = SCNVector3(1.0, 0.5, 1.0)
        root.addChildNode(capNode)

        // Spots on cap
        let spotMat = mat(.white, shiny: shiny)
        let spotPositions: [(Float, Float, Float)] = [
            (-0.15, 1.0, 0.2), (0.2, 1.0, 0.1), (0.0, 1.05, -0.15), (-0.1, 0.95, 0.3)
        ]
        for (x, y, z) in spotPositions {
            let spot = SCNSphere(radius: 0.06)
            spot.firstMaterial = spotMat
            let sNode = SCNNode(geometry: spot)
            sNode.position = SCNVector3(x, y, z)
            root.addChildNode(sNode)
        }

        // Stem
        let stem = SCNCylinder(radius: 0.18, height: 0.6)
        stem.firstMaterial = mat(stemColor, shiny: shiny)
        let stemNode = SCNNode(geometry: stem)
        stemNode.position = SCNVector3(0, 0.35, 0)
        root.addChildNode(stemNode)

        let headNode = capNode

        let leftEye = buildEye(radius: 0.06)
        leftEye.position = SCNVector3(-0.08, 0.5, 0.16)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.06)
        rightEye.position = SCNVector3(0.08, 0.5, 0.16)
        root.addChildNode(rightEye)

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: nil, hatAttachPoint: SCNVector3(0, 1.15, 0),
            boundingHeight: 1.2
        )
    }

    // MARK: - Chonk

    private func buildChonk(shiny: Bool) -> SpeciesModel {
        let root = SCNNode()
        let bodyColor = shiny ? NSColor.systemOrange : NSColor(red: 0.6, green: 0.45, blue: 0.3, alpha: 1.0)

        // Extra chonky body
        let body = SCNSphere(radius: 0.55)
        body.firstMaterial = mat(bodyColor, shiny: shiny)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.5, 0)
        bodyNode.scale = SCNVector3(1.1, 0.9, 1.0)
        root.addChildNode(bodyNode)

        // Head - slightly smaller sphere on top
        let head = SCNSphere(radius: 0.3)
        head.firstMaterial = mat(bodyColor, shiny: shiny)
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 1.05, 0.05)
        root.addChildNode(headNode)

        // Ears
        for xOff: Float in [-0.18, 0.18] {
            let ear = SCNCone(topRadius: 0, bottomRadius: 0.08, height: 0.15)
            ear.firstMaterial = mat(bodyColor, shiny: shiny)
            let eNode = SCNNode(geometry: ear)
            eNode.position = SCNVector3(xOff, 1.32, 0)
            root.addChildNode(eNode)
        }

        let leftEye = buildEye(radius: 0.07)
        leftEye.position = SCNVector3(-0.12, 1.1, 0.26)
        root.addChildNode(leftEye)

        let rightEye = buildEye(radius: 0.07)
        rightEye.position = SCNVector3(0.12, 1.1, 0.26)
        root.addChildNode(rightEye)

        // Nose
        let nose = SCNSphere(radius: 0.03)
        nose.firstMaterial = mat(NSColor(red: 1.0, green: 0.5, blue: 0.5, alpha: 1.0), shiny: shiny)
        let noseNode = SCNNode(geometry: nose)
        noseNode.position = SCNVector3(0, 1.02, 0.32)
        root.addChildNode(noseNode)

        // Belly highlight
        let belly = SCNSphere(radius: 0.35)
        belly.firstMaterial = mat(bodyColor.blended(withFraction: 0.3, of: .white) ?? bodyColor, shiny: shiny)
        let bellyNode = SCNNode(geometry: belly)
        bellyNode.position = SCNVector3(0, 0.4, 0.15)
        bellyNode.scale = SCNVector3(0.8, 0.7, 0.5)
        root.addChildNode(bellyNode)

        // Stubby tail
        let tail = SCNSphere(radius: 0.07)
        tail.firstMaterial = mat(bodyColor, shiny: shiny)
        let tailNode = SCNNode(geometry: tail)
        tailNode.position = SCNVector3(0, 0.4, -0.45)
        root.addChildNode(tailNode)

        // Tiny paws
        for (x, z) in [(Float(-0.2), Float(0.15)), (Float(0.2), Float(0.15))] {
            let paw = SCNSphere(radius: 0.07)
            paw.firstMaterial = mat(bodyColor, shiny: shiny)
            let pNode = SCNNode(geometry: paw)
            pNode.position = SCNVector3(x, 0.04, z)
            root.addChildNode(pNode)
        }

        return SpeciesModel(
            rootNode: root, headNode: headNode,
            leftEyeNode: leftEye, rightEyeNode: rightEye,
            mouthNode: noseNode, hatAttachPoint: SCNVector3(0, 1.35, 0),
            boundingHeight: 1.4, tailNode: tailNode
        )
    }
}
